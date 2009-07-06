#!/usr/bin/env ruby

require 'logger'
require 'fileutils'

require 'rubygems'
require 'daemons'

CUR_DIR=File.expand_path(File.dirname(__FILE__))
LOG_DIR=File.expand_path(File.join(CUR_DIR,'log'))
DIR_ROOT=File.expand_path(File.join(CUR_DIR,'..'))
$:.unshift File.join(CUR_DIR,'lib')

class Runner
  
  def initialize(mode=:default)

    if mode == :test
      ENV["RAILS_ENV"] = "test"
      eval("TESTING=true")
      @runlog = Logger.new(STDOUT)
      run_crawl(:services => false, :daemonize => false)
    elsif mode == :load
      eval("TESTING=true")
      ENV["RAILS_ENV"] = "development"
      @runlog = Logger.new(STDOUT)
      run_crawl(:services => false, :daemonize => false)
    elsif mode == :default
      daemonize
      run_loop
    else
      STDERR.puts "Unknown mode try :default or :test"
    end

  end

private
  def daemonize
    if File.exist?(File.join(LOG_DIR, 'crawl.pid'))
      STDERR.puts "Crawler already running"
      exit(1)
    end

    Daemonize.daemonize('crawl-daemon','popnhot')

    @runlog = Logger.new(File.join(LOG_DIR,'run.log'))
    @runlog.info("Starting with pid: #{Process.pid} and parent :  #{Process.ppid}")

    File.open(File.join(LOG_DIR, 'crawl.pid'),'wb'){|f| f  << Process.pid }

    begin

      at_exit{ cleanup_pid }
      Signal.trap('TERM'){ cleanup_pid; exit(0) }
      Signal.trap('KILL'){ cleanup_pid; exit(0) }
      Signal.trap('INT'){ cleanup_pid; exit(0) }

    rescue => e
      File.open("#{LOG_DIR}/fatal_error.log","wb+") do|f|
        f << "Fatal Error at: #{Time.now}\n\n"
        f << "Error: #{e.message}\n#{e.backtrace.join("\n")} \n=> #{__FILE__}"
      end
      cleanup_pid 
      @runlog.info("Exiting with fatal error: #{Process.pid}")
      exit(1)
    end

    if File.exist?(File.join(LOG_DIR, 'crawl.pid'))
      @runlog.info("Started with pid: #{Process.pid}")
    else
      @runlog.info("We lost the pid!! #{Process.pid}")
    end
  end

  def run_loop
    # run the daemon every 10 minutes
    loop do
      @runlog.info "starting run..."
      exec_crawl
      @runlog.info "waiting 10 minutes for next run since #{Time.now}..."
      sleep(60*10) # wait 10 minutes before next run
    end
  end

  def cleanup_pid()
    if Process.pid.to_i == File.read(File.join(LOG_DIR, 'crawl.pid')).to_i
      @runlog.info("Exiting: #{Process.pid}, with parent: #{Process.ppid}")
      FileUtils.rm(File.join(LOG_DIR, 'crawl.pid')) 
    end
  end

  def run_crawl(options={})
    require 'feed_crawler'
    fc = FeedCrawler.new(options)
    fc.run
  end

  def exec_crawl(options={})
    #@crawler = Daemons.call(:multiple => true) do
    pid = fork do
      begin
        run_crawl(options)
      rescue ::Object => e
        File.open("#{LOG_DIR}/fatal_error.log","wb+") do|f|
          f << "Error: #{e.message}\n#{e.backtrace.join("\n")} \n=> #{__FILE__}"
        end
      end
    end
    timer = Time.now
    until( (cpid=Process.waitpid(pid,Process::WNOHANG)) and cpid == pid )
      sleep 10
      @runlog.info "Crawler elapsed time: #{Time.now - timer}"
      if (Time.now - timer).to_i >= (60*10)
        system("kill -9 #{pid}")
      end
    end
  end

end

case ARGV[0]
when 'test'
  Runner.new :test
when 'load'
  Runner.new :load
else
  Runner.new
end

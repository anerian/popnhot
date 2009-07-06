require 'ostruct'
require 'stream_xml/parse_reader'
require 'news_feed/atom'
require 'news_feed/rss'
require 'crawl/extract'
require 'crawl/tmz'
require 'crawl/people'
require 'crawl/usmag'
require 'crawl/pop_sugar'
require 'crawl/eonline'
require 'crawl/celebuzz'
require 'crawl/pinknblog'

if defined?(TESTING) and TESTING
  $logger = Logger.new(File.join(LOG_DIR,'test.log'))
elsif ENV["MERB_ENV"] == "test"
  $logger = Logger.new(STDOUT)
else
  puts "creating logger"
  $logger = Logger.new(File.join(LOG_DIR,'crawl.log'))
end

module Logging
  def info(msg)
    $logger.info(msg)
  end
  def debug(msg)
    $logger.debug(msg)
  end
  def error(msg)
    $logger.error(msg)
  end
end

module Crawl
  class Session
    class << self
      include Logging
    end
  end
  class Extract
    class << self
      include Logging
    end
  end
end

require 'uri'
require 'fileutils'
require 'rubygems'
require 'hpricot'

$:.unshift << File.expand_path(File.join(File.dirname(__FILE__),'lib'))

require 'news_feed/atom'
require 'news_feed/rss'

mock_dir = "specs/mocks"
curb = Curl::Easy.new

def grab_resource(mock_dir, curb, url)
  curb.url = url
  uri = URI.parse(url)
  base_name = File.basename(uri.path)
  dir_name = File.dirname(uri.path)
  puts "#{uri.host}: #{dir_name} => #{base_name}"
  pathbase = File.join(mock_dir, uri.host, dir_name)
  FileUtils.mkdir_p(pathbase)

  File.open(File.join(pathbase,base_name),"wb") do|f|
    curb.on_body{|d| f << d ; d.size }
    curb.perform
  end
  puts "Saved #{url}"
end


url = "file://#{File.expand_path(mock_dir)}/pinkisthenewblog.com/home/feed"
fa = NewsFeed::RSS.new
# mock out request
title = ""
link = ""
items = []

fa.read(url) do |cfg|
  cfg.title {|title| title = title }
  cfg.link {|link| link = link }
  cfg.item {|item| items << item }
end


for item in items do
  puts item[:link]
  grab_resource( mock_dir, curb, item[:link] )
  doc = Hpricot("<html><body>#{item[:description]}</body></html>")
  img = doc.at('img')
  if img and img['src']
    puts img['src']
    grab_resource( mock_dir, curb, img['src'] )
  end
end


=begin

[ "http://img2.timeinc.net/people/i/2008/news/080728/pierce_brosnan150.jpg",
  "http://img2.timeinc.net/people/i/2008/features/insider/080728/halle_berry150.jpg",
  "http://img2.timeinc.net/people/i/2008/features/tvblog/080728/rhimes_heigl150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080728/blake_lively150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080728/jolie_pitt150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080519/kevin_federline150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080714/kidman_urban150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080728/cvr_nylon150.jpg",
  "http://img2.timeinc.net/people/i/2008/news/080728/probst_chenoweth150.jpg"].each do|url|
  curb.url = url
  uri = URI.parse(url)
  base_name = File.basename(uri.path)
  dir_name = File.dirname(uri.path)
  puts "#{uri.host}: #{dir_name} => #{base_name}"
  pathbase = File.join(mock_dir, uri.host, dir_name)
  FileUtils.mkdir_p(pathbase)
  File.open(File.join(pathbase,base_name),"wb") do|f|
    curb.on_body{|d| f << d ; d.size }
    curb.perform
  end
  puts "Saved #{url}"
end
=end

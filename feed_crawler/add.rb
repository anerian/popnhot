CUR_DIR=File.expand_path(File.dirname(__FILE__))
LOG_DIR=File.expand_path(File.join(CUR_DIR,'log'))
DIR_ROOT=File.expand_path(File.join(CUR_DIR,'..'))

$:.unshift File.join(CUR_DIR,'lib')
require 'merb_startup'

DIR_ROOT=File.join(CUR_DIR,'..') unless defined?(DIR_ROOT)
LOG_DIR=File.join(CUR_DIR,'log') unless defined?(LOG_DIR)
  
# startup the merb environment
Merb.load_externally(DIR_ROOT)
    
require 'crawl'

#new_feed = {:klass => 'PopSugar',
#            :content_type => 'application/rss+xml',
#            :url => 'http://feeds.feedburner.com/popsugar',
#            :title => 'POPSUGAR - Celebrity Gossip & News',
#            :link => 'http://www.popsugar.com/'}
#new_feed = {:klass => 'Eonline',
#            :content_type => 'application/rss+xml',
#            :url => 'http://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml',
#            :title => 'E! Online - Top Stories',
#            :link => 'http://www.eonline.com/'}
#new_feed = {:klass => 'Celebuzz',
#            :content_type => 'application/rss+xml',
#            :url => 'http://www.celebuzz.com/rss/stories-rss.xml',
#            :title => 'Celeb Gossip and Celebrity Gossip News - Celebuzz',
#            :link => 'http://www.celebuzz.com/'}
new_feed = {:klass => 'PinknBlog',
            :content_type => 'application/rss+xml',
            :url => 'http://pinkisthenewblog.com/home/feed',
            :title => "Pink is the New Blog -  Everybody's Business Is My Business",
            :link => 'http://pinkisthenewblog.com/'}
Feed.create!(new_feed)
puts "Created feed: #{new_feed.inspect}"

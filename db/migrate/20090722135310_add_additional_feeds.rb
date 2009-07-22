class AddAdditionalFeeds < ActiveRecord::Migration
  def self.up
    new_feed = {:klass => 'PopSugar',
                :content_type => 'application/rss+xml',
                :url => 'http://feeds.feedburner.com/popsugar',
                :title => 'POPSUGAR - Celebrity Gossip & News',
                :link => 'http://www.popsugar.com/'}
    Feed.create!(new_feed)
    puts "Created feed: #{new_feed.inspect}"
    new_feed = {:klass => 'Eonline',
                :content_type => 'application/rss+xml',
                :url => 'http://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml',
                :title => 'E! Online - Top Stories',
                :link => 'http://www.eonline.com/'}
    Feed.create!(new_feed)
    puts "Created feed: #{new_feed.inspect}"
    new_feed = {:klass => 'Celebuzz',
                :content_type => 'application/rss+xml',
                :url => 'http://www.celebuzz.com/rss/stories-rss.xml',
                :title => 'Celeb Gossip and Celebrity Gossip News - Celebuzz',
                :link => 'http://www.celebuzz.com/'}
    Feed.create!(new_feed)
    puts "Created feed: #{new_feed.inspect}"
    new_feed = {:klass => 'PinknBlog',
                :content_type => 'application/rss+xml',
                :url => 'http://pinkisthenewblog.com/home/feed',
                :title => "Pink is the New Blog -  Everybody's Business Is My Business",
                :link => 'http://pinkisthenewblog.com/'}
    Feed.create!(new_feed)
    puts "Created feed: #{new_feed.inspect}"
  end

  def self.down
  end
end

class Feed < ActiveRecord::Base
  has_many :posts, :dependent => :destroy
  validates_presence_of     :title, :url, :content_type, :link
  validates_uniqueness_of   :title, :url, :link

  def self.setup( feed_url, content_type = 'application/rss+xml', klass = News::Feed)
    feed = klass.new(curb_get(feed_url), content_type)
    Feed.new( :title => feed.title, 
              :link => feed.links.first,
              :url => feed_url,
              :klass => klass.to_s,
              :content_type => content_type,
              :subtitle => feed.subtitle )
  end

  # load posts to associate to this feed
  def refresh_posts( tagger, all_tags = nil )
    require 'news/feed'

    all_tags ||= Tag.find(:all)

    puts "refreshing posts with: #{self.klass}"
    feed = self.klass.constantize.new( curb_get(self.url), self.content_type )

    feed.items.each_with_index do|item,count|
      timer = Time.now
      puts "loading post: #{item.title}..."
      post = Post.new(:title => item.title,
                      :link => item.links.first,
                      :image => item.image,
                      :body => item.body,
                      :author => item.authors.first,
                      :published_at => item.published,
                      :feed_id => self.id,
                      :tag_list => item.categories )
      post.summarize!
      # check for images in the body pick the first one as the icon to use and use rmagick to scan it down
      post.retag(tagger,all_tags) if post.tag_list.empty?
      puts post.permalink
      other = Post.find_by_title(post.title)
      if post.valid? and (other.nil? or other.published_at != post.published_at)
        post.save!
        puts "post: #{item.title}, loaded in #{Time.now - timer} with tags: #{post.tag_list.inspect}, item: #{count} of #{feed.items.size}"
      else
        puts "skipping: #{item.title}, item: #{count} of #{feed.items.size}"
      end
    end
  end
end

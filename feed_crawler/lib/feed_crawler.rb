#require 'merb_startup'

DIR_ROOT=File.join(CUR_DIR,'..') unless defined?(DIR_ROOT)
LOG_DIR=File.join(CUR_DIR,'log') unless defined?(LOG_DIR)

class FeedCrawler
  def initialize(options={})
    @options = options
    # startup the merb environment
    #Merb.load_externally(DIR_ROOT)
    require "#{DIR_ROOT}/config/environment.rb" # load rails env
    require 'crawl'
    require 'rbtagger'
    require 'delicious_post'
    require 'timeout'
    require 'normalize_tags'

    if defined?(TagList)
      TagList.class_eval do
        def add(*names)
          extract_and_apply_options!(names)
          concat(names.map{|n| Normalize::Tags.normalize(n) }.uniq)
          clean!
          self
        end
      end
    end

    log "loading feed records..."
    # load feeds from database
    @feeds = Feed.find(:all)
    log @feeds.inspect
    if @feeds.empty?
      seed([
        {:klass => 'Tmz', 
         :content_type => 'application+rss/xml',
         :url => 'http://www.tmz.com/rss.xml',
         :title => 'TMZ.com',
         :link => 'http://www.tmz.com'},
        {:klass => 'People',
         :content_type => 'application+rss/xml',
         :url => 'http://rss.people.com/web/people/rss/topheadlines/index.xml',
         :title => 'People.com',
         :link => 'http://www.people.com'},
        {:klass => 'UsMag',
         :content_type => 'application/atom+xml',
         :url => 'http://feeds.usmagazine.com/celebrity_news/atom',
         :title => 'Usmagazine.com',
         :link => 'http://www.usmagazine.com/'}
      ])
      @feeds = Feed.find(:all)
    end
    @tagger = Word::Tagger.new( Tag.find(:all).map{|t| t.name}, :words => 4 )
    @last_sent_delicious = Time.now
    @count_added = 0
  end

  def post_to_delicious(post)
    if @options and @options.key?(:services) and !@options[:services]
      log("[Delicious]: skipping #{post.title}")
      return
    end

    begin
      dpost = DeliciousPost.new( post )
      dpost.add
      @count_added += 1
    rescue => e
      log("[Delicious]: error #{e.message}, #{e.backtrace.join("\n")}")
    end
  end
 
  def log(msg)
    $logger.info(msg)
  end

  def seed(feeds)
    feeds.each do|f|
      log "seeding feed: #{f.inspect}"
      Feed.create(f)
    end
    log "seeded #{feeds.size}"
  end

  def run
    timer = Time.now
    log "running... #{timer}"
    # open a new session
    Crawl::Session.run(DIR_ROOT) do|cfg|

      for feed in @feeds do

        cfg.extractor(feed).posts do|post, feed_obj|
          log "processing post: #{post[:link].inspect}"

          thumb_path = post.delete(:thumb_path)
          video = post.delete(:video)
          if thumb_path
            thumb_base = thumb_path.gsub(/#{DIR_ROOT}\/staging/,'/files/')
            public_path = File.dirname(File.join(DIR_ROOT,'public',thumb_base))
            if File.exist?(thumb_path)
              FileUtils.mkdir_p(public_path)
              # move image to public folder
              FileUtils.mv(thumb_path,public_path)
              log "save thumb #{thumb_path} to #{public_path}"
              post[:image] = thumb_base
            end
          elsif video
            post[:image] = "/images/video.png"
          end
          post[:feed_id] = feed_obj.id

          # check for duplicates
          p = Post.find_by_link(post[:link].strip)
          if p
            #log "post duplicate: #{post[:link].inspect}"
          else
            if post[:tag_list].blank? or post[:tag_list].size < 4
              log "post: #{post[:title].inspect}, has no tags, attempting to auto tag"
              tags = @tagger.execute("#{post[:title]} #{post[:summary]}".gsub(/[^\w]/,' ').downcase)
              if tags
                post[:tag_list] = tags
                if tags.size > 3
                  post[:tag_list] = tags.select do|t|
                    tag = Tag.find_by_name(t)
                    tag.name? if tag
                  end
                  if post[:tag_list].size > 3
                    post[:tag_list] = post[:tag_list][0..3]
                  end
                end
                log "post: #{post[:title].inspect} => #{post[:tag_list].inspect}"
              else
                log "post: #{post[:title].inspect}, has no recommended tags..."
              end
            end
            tag_list = (post[:tag_list]||[]).map{|n| Normalize::Tags.normalize(n).downcase }.uniq
            post[:tag_list] = Normalize::Tags.selective(tag_list)
            rp = Post.new(post)
            if rp.save
              log "created new post: #{post[:title].inspect}"
              post_to_delicious(rp)
            else
              log "failed to create new post: #{post[:title].inspect}, #{rp.errors.inspect}"
            end
          end

        end.run do|ecfg|
          ecfg.dup_check do|ptitle,plink|
            p = Post.find_by_link(plink.strip)
            if p
              log "duplicate: #{plink.inspect}"
              true
            else
              log "not duplicate: #{plink.inspect}"
              false
            end
          end
        end

      end

    end
    log "finished run after: #{Time.now - timer} seconds..."
    log "finished adding #{@count_added} posts to delicious after: #{Time.now - timer} seconds..."
  end
end

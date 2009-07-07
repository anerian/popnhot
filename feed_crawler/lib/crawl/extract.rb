require 'logger'
require 'curb'
gem 'rmagick'
require 'RMagick'

module Crawl

  # setup the session
  #
  #  Crawl::Session.run(dir_root) do|cfg|
  #
  #    for feed in feeds do
  #      # everytime a post is ready for this feed
  #      cfg.extractor(feed).posts do|post|
  #        # do something interesting with the post object
  #        # like save it to a database
  #      end.run
  #    end
  #
  #  end
  #
  class Session
    def initialize(dir_root)
      @multi = Curl::Multi.new
      @dir_root = dir_root
      @active_requests = 0
    end

    # s.request(link) do|success,body|
    #   body if success
    # end
    def request(link, &blk)
      link = hook(link)
      log "request: #{link} -> #{blk.inspect}"
      @multi.add( Curl::Easy.new(link) do|c|
        c.follow_location = true
        c.headers["User-Agent"] = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.20"
        c.on_success{|curl| yield(true,  curl.body_str) ; @active_requests -= 1 ; log("request:#{link} success") }
        c.on_failure{|curl,code| yield(false, curl.body_str) ; @active_requests -= 1 ; log("request:#{link} failure with curl code: #{code}") }
      end )
      # returns active request count
      @active_requests += 1
      @active_requests
    end

    def extractor(feed)
      klass = [:People,:Tmz,
               :UsMag,:PopSugar,
               :Eonline,:Celebuzz,
               :PinknBlog].find{|k| k == feed.klass.to_sym }
      # Crawl::Extract
      klass = eval(klass.to_s)
      obj = klass.new(@dir_root,self,feed, feed.url,NewsFeed.klass_for(feed.content_type))
      obj
    end

    # run the session
    def self.run(dir_root)
      s = new(dir_root)
      yield s
      s.run
    end

    def run
      @multi.perform until @active_requests == 0
    end

    def hook(link) # used by specs to change request to file system
      link
    end

    def log(msg)
      Session.info(msg)
    end

  end

  class Extract
    attr_reader :title, :link
    # c = Crawl::Extract.new(session, feed_obj, 'url..',Feed::Atom)
    def initialize(dir_root,session, feed, feed_url, feed_klass)
      @dir_root = dir_root
      @post_cb = lambda{|p,fo| nil }
      @feed_url = feed_url
      @session = session
      @feed_klass = feed_klass
      @feed = feed
      @dup_check = lambda{|ptitle,plink| false }
    end

    def run
      yield self if block_given?
      @session.request(@feed_url) do|status,body|
        if status
          extract_valid_post(body)
        else
          report_post_request_error(body)
        end
      end
    end

    def dup_check
      @dup_check = lambda{|ptitle,plink| yield ptitle, plink }
    end

    def report_post_request_error(body)
      # report error
       error "Failed to request feed: #{@feed_url}"
    end

    def extract_valid_post(body)
      parser = @feed_klass.new
      parser.parse( body ) do|cfg|
        cfg.title do|t|
          @title = t # the feed title
        end

        cfg.link do|l|
          @link = l # the feed link
        end

        cfg.item do|item|
          log "item: #{item[:title]}"
          # fetch the original article
          uri = URI.parse(item[:link])
          #puts "got an #{item.inspect}"
          return if @dup_check.call(item[:title], item[:link])
          #if !@dup_check.call(item[:title], item[:link])

            @session.request(item[:link]) do|success,body|
              log "post request response(#{item[:link]})"
              # pass body if success to feed extractor
              timer = Time.now
              begin

                extracted_post = extract(body,uri,item)

                extracted_post[:title] = filter(:title, item[:title],item)
                extracted_post[:link] = filter(:link, item[:link],item)
                extracted_post[:published_at] = filter(:published_at, item[:published_at],item)
                extracted_post[:author] = filter(:author, item[:author],item)
                extracted_post[:tag_list] = filter(:category, item[:category],item)
                extracted_post[:summary] = filter(:description, item[:description],item)
                if extracted_post[:video]
                  extracted_post.delete(:video)
                  extracted_post[:image] = "/images/video.png"
                end
                if extracted_post[:thumb_path]
                  stage_image(extracted_post) do|ep|
                    # emit to caller
                    @post_cb.call( ep, @feed )
                    log "post(#{ep[:link]}) time: #{Time.now - timer}"
                  end
                else
                  @post_cb.call( extracted_post, @feed )
                  log "post(#{extracted_post[:link]}) time: #{Time.now - timer}"
                end
              rescue => e
                error "#{e.message}\n#{e.backtrace.join("\n")}"
              end
            end

          #end
        end

      end
    rescue => e
      error "#{e.message}\n#{e.backtrace.join("\n")}"
    end

    # override this to extract specific elements, e.g. a post image
    def extract(body,uri,item_content={})
      {:body => normalize((Hpricot(body)/'body').inner_html), :thumb_path=>nil, :has_video=>false }
    end

    def filter(key,value,item)
      value
    end

    # c.posts do|post|
    #   post.source_url
    #   post.title
    #   post.link
    #   post.thumb
    #   post.summary
    #   post.body
    #   post.tags
    #   post.author
    # end
    def posts # proxy the posts struct
      @post_cb = lambda{|post,fobj| yield post,fobj }
      self
    end

  private
 
    def normalize(str)
      # herustic, run the regex 3 times over the string, to get nested empty tags
      str.gsub(/<([^>]*)\s*?.*>[\n\t\s\r]*<\/\s*\1\s*>/,'').
          gsub(/<([^>]*)\s*?.*>[\n\t\s\r]*<\/\s*\1\s*>/,'').
          gsub(/<([^>]*)\s*?.*>[\n\t\s\r]*<\/\s*\1\s*>/,'').
          strip.gsub(/\s+/,' ')
    end

    def stage_image(ep)
      ep = ep.clone
      src = ep[:thumb_path]
      if !src.match( /^http:|^https:/ )
        # prepend host of current document
        if src.match(/^\//) # absolute path
          src = "http://#{uri.host}#{src}"
        else # relative, need to include File.dirname(uri.path)
          src = "http://#{uri.host}/#{File.dirname(uri.path)}/#{src}"
        end
      elsif src.match(/^\/\//) # no protocol inferred 
        src = "http:#{src}"
      end
      image_uri = URI.parse(src)

      img_path = File.join(@dir_root,"staging",image_uri.host,image_uri.path)
      thumb_path = thumb_path(img_path)
      @session.request(src) do|success,buffer|
        # ensure parent folder exists
        FileUtils.mkdir_p(File.dirname(img_path))
        log "saving image: #{thumb_path}"
        # save original image data
        File.open(img_path,"w") do|f|
          f << buffer
        end
        # convert saved image to thumb
        resize_image(img_path,thumb_path)
        ep[:thumb_path] = thumb_path
        yield ep
      end

      thumb_path 
    end

    def thumb_path(orig_path)
      base = File.dirname(orig_path)
      npath = File.join(base,'thumbs',File.basename(orig_path)).gsub(/\.#{File.extname(orig_path)}$/,'.gif')
      FileUtils.mkdir_p(File.dirname(npath))
      npath
    end

    def resize_image(orig_path,thumb_pathname)
      if File.exist?(orig_path) and File.size(orig_path) > 0
        log "create thumb for: #{orig_path} as #{thumb_path}"

        pic = Magick::Image.read(orig_path).first
        pic.resize_to_fill!(125, 125, Magick::NorthGravity)
        pic.write(thumb_pathname)

      else
        log "skipping file either doesn't exist or is zero bytes"
      end
    rescue => e
      error "#{e.message}\n#{e.backtrace.join("\n")}"
    end

    def log(msg)
      Extract.info(msg)
    end
    
    def error(msg)
      Extract.error(msg)
    end

  end
end

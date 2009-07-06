class DeliciousPost
  ADD_URL_BASE="https://api.del.icio.us/v1/posts/add"
  
  def initialize(post)
    @post = post
    @curl = Curl::Easy.new do|cfg|
      cfg.headers["User-Agent"] = "popnhot.com"
    end
  end

  def add
    url = "#{ADD_URL_BASE}?url=#{absolute_url(:post,@post)}&description=#{URI.escape(@post.title)}"
    url = "#{url}&tags=#{URI.escape(@post.tag_list.to_s.gsub(/,/,'+'))}" unless @post.tags.empty?
    log( "[Delicious]: adding #{@post.id}:#{@post.title}, through URL: #{url}")
    @curl.url = url
    # setup user details and basic auth
    @curl.userpwd = "popnhot:popnhot-del"
    retry_count = 0
    begin
      @curl.perform # blocks all threads, TODO: use the existing session multi handle
      if @curl.response_code == 200
        res = Hpricot.XML(@curl.body_str)
        if res.at('result')
          log( "[Delicious]: #{res.at('result')['code']}, for #{@post.id}:#{@post.title}")
        else
          log("[Delicious]: Failed to read response for post: #{@post.id}:#{@post.title}")
        end
      else
        if retry_count == 0
          log("[Delicious]: received #{@curl.response_code} status from delicious with last post #{@post.id}:#{@post.title}, waiting 2 seconds to retry")
          sleep 2
          retry_count += 1
        else
          log("[Delicious]: received #{@curl.response_code} status from delicious with last post #{@post.id}:#{@post.title}, giving up already retried")
        end
        retry
      end
    rescue => e
      log("[Delicious]: error: #{e.message} @post.id}:#{@post.title}\n\n#{e.backtrace}")
    end
  end
 
  def absolute_url(name, rparams={})
    uri = Merb::Router.generate(name, rparams,
      { :controller => 'posts',
        :action => 'show',
        :format => 'html'
      }
    )
    uri = Merb::Config[:path_prefix] + uri if Merb::Config[:path_prefix]
    "http://www.popnhot.com#{uri}"
  end
    
  def log(msg)
    Crawl::Session.info(msg)
  end
 
end

require 'curb'

module NewsFeed
  class Base
    def initialize
      @title_cb = lambda {|t|}
      @link_cb = lambda {|t|}
      @item_cb = lambda {|t|}
    end

    def read( url )
      request(url)
    end
 
    # call backs
    def title
      @title_cb = lambda {|t| yield t }
    end

    def link
      @link_cb = lambda {|t| yield t }
    end

    def item
      @item_cb = lambda {|t| yield t }
    end

  private
    def request(url)
      buffer = "" # maybe we can use a StringIO object here and keep less in memory??
      curl = Curl::Easy.new(url) do |cfg|
        cfg.headers["User-Agent"] = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.20"
        cfg.follow_location = true
        cfg.on_body { |data| buffer << data; data.size }
      end
      curl.perform
      buffer
    end
  end
  
  # given a mime type return a NewsFeed klass (Atom or RSS)
  def self.klass_for(mime_type)
    mime_type.match(/rss/) ? NewsFeed::RSS : NewsFeed::Atom
  end

end

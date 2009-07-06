require 'news_feed/base'
require 'stream_xml/parse_reader'

module NewsFeed
  #
  # fa = NewsFeed::RSS.new
  #
  # fa.read( 'feed url' ) do|cfg|
  #   cfg.title do|title|
  #   end
  #
  #   cfg.link do|link|
  #   end
  #
  #   cfg.item do|item|
  #   end
  #
  # end
  class RSS < Base
    def initialize
      super
    end

    def read( url )
      yield self
      parse( super(url) )
    end

    def parse(buffer)
      yield self if block_given?
      StreamXML::ParseReader.execute_buffer(buffer) do|ctx|

        ctx.content_for('//rss/channel/title') {|title| @title_cb.call(title) }
        ctx.content_for('//rss/channel/link') {|link| @link_cb.call(link) }

        ctx.collection(:items,'//rss/channel/item') do|si|
          si.content_for('//rss/channel/item/title')
          si.content_for('//rss/channel/item/link')
          si.content_for('//rss/channel/item/description')
          si.content_for('//rss/channel/item/content:encoded', :as => :description)
          si.content_for('//rss/channel/item/category', :collect => true)
          si.content_for('//rss/channel/item/dc:creator', :as => :author, :replace => true)
          si.content_for('//rss/channel/item/dc:date', :as => :published_at, :replace => true)
          si.content_for('//rss/channel/item/pubDate', :as => :published_at, :replace => true)
          si.attr_for('//rss/channel/item/media:group/media:thumbnail', :capture => :url, :as => :thumbnail)
          si.attr_for('//rss/channel/item/media:group/media:content', :capture => :url, :as => :image, :match => {:type => /image/})
          si.content_for('//rss/channel/item/feedburner:origLink', :as => :link, :replace => true)
        end.capture do|item|
          @item_cb.call(item)
        end
      end
    end

  end
end

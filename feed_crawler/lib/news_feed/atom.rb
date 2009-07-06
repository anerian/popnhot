require 'news_feed/base'
require 'stream_xml/parse_reader'

module NewsFeed
  #
  # fa = NewsFeed::Atom.new
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
  class Atom < Base
    def initialize
      super
    end

    def read( url )
      yield self
      parse( super(url) )
    end

    def parse( buffer )
      yield self if block_given?
      StreamXML::ParseReader.execute_buffer(buffer) do|ctx|
        ctx.content_for('//feed/title'){|title| @title_cb.call(title) }
        ctx.attr_for('//feed/link',:capture => :href, :match => {:type => /text\/html/} ){|link| @link_cb.call(link) }
        ctx.collection(:entries,'//feed/entry') do|entry|
          entry.content_for('//feed/entry/title')
          entry.attr_for('//feed/entry/link',:capture => :href, :match => {:type => /text\/html/}, :as => :link )
          entry.content_for('//feed/entry/content', :as => :body)
          entry.content_for('//feed/entry/summary', :as => :description)
          entry.attr_for('//feed/entry/category', :capture => :term, :collect => true, :as => :category)
          entry.content_for('//feed/entry/author/name', :collect => true, :as => :author)
          entry.content_for('//feed/entry/published', :as => :published_at )
        end.capture do|entry|
          # normalize keys
          entry[:link] = entry[:link].first if entry[:link].size == 1
          entry[:author] = entry[:author].first if entry[:author].size == 1
          @item_cb.call(entry)
        end
      end
    end

  end
end

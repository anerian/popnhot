#!/usr/bin/env ruby

# this will download an rss/atom feed
require 'ostruct'
#require 'rss/1.0'
#require 'rss/2.0'
#require 'open-uri'
require 'curb'
require 'rubygems'
require 'hpricot'
require 'atom'
require File.join(File.dirname(__FILE__),'parse')


module News
  class Feed
    attr_reader :items, :type, :title, :links, :subtitle, :authors, :updated, :icon, :logo, :categories

    def initialize(feed_xml,type='application/rss+xml')
      @items = [] 
      @type = type
      parse( feed_xml )
    end

    private
      def parse( content )
        if @type.match(/rss/)
          feed = News::Parse.extract(content) #RSS::Parser.parse(content, false)
          @title = feed.title
          @links = [feed.home_url]
          @subtitle = feed.description
          @items = feed.items.collect do|item|
            OpenStruct.new({:title => item.title, 
                            :links => [item.link],
                            :summary => item.description,
                            :image => "",
                            :body => item.description,
                            :published => item.publication_date,
                            :authors => [item.author],
                            :categories => item.category})
          end
        else
          feed = Atom::Feed.new(content)
          @title = feed.title
          @subtitle = feed.subtitle
          @authors = feed.authors
          @links = feed.links.map{|l| l.href}
          @updated = feed.updated
          @icon = feed.icon
          @logo = feed.logo
          @categories = feed.categories
          @items = feed.entries.collect do |entry|
            OpenStruct.new({:title => entry.title, 
                            :links => entry.links.collect{|l| l.href },
                            :image => "",
                            :summary => entry.summary,
                            :body => entry.content.value,
                            :authors => entry.authors.collect{|a| a.name },
                            :published => entry.published,
                            :updated => entry.updated,
                            :categories => entry.categories.map{|c| c.to_s } })

          end
        end

        @items.each do|item|
          item.image = image_extract(item.body)
          fixup_image(item)
        end
      end

      def image_extract(content)
        # check for images in the body tag
        doc = Hpricot(content)
        if doc
          # the first image will hopefully do?
          img = doc.at("img")
          if img
            img.swap(%Q(<img class="image_thumb" src="#{img['src']}" height="80" width="120"/>))
            img.to_html
          end
        end
      end

      def fixup_image(item)
        doc = Hpricot("<html><body>#{item.image}</body></html>")
        (doc/"img").each do|image|
          n_image = %Q(<img class="image_thumb" src="#{image['src']}" height="80" width="120"/>)
          image.swap(n_image)
        end
        item.image = doc.at("body").inner_html
      end

  end

  class UsMag < Feed
    def initialize(feed_xml,type='application/rss+xml')
      super(feed_xml, type)
      host = "http://www.usmagazine.com"
      @links = ["#{host}/celebrity_news"]
      @items.each do|item|
        image_extract(item.body)
        fixup_image(item)
        item.links[0] = item.links.first.gsub(/http:\/\//,'').gsub(/^.*\//,host+'/')
      end
    end
  end

  # specialize the people feed to extract image markup
  class People < Feed
    def initialize(feed_xml,type='application/rss+xml')
      super(feed_xml, type)
      fixup
      @items.each do|item|
        image_extract(item.body)
        fixup_image(item)
      end
    end
  private
    def fixup
      @items.each do|item|
        doc = Hpricot(curb_get(item.links.first))
        found = nil
        # check for images
        image = doc.at('img.imgLeft')
        image ||= doc.at('div.articleBody img')
        image ||= doc.at('div.entrytext img')
        image ||= doc.at('div.articleBody object') ? "<img src='/images/video.png' height='80' width='80'/>" : ''
        item.image = image.respond_to?(:to_html) ? image.to_html : image if image

        (doc/'div.articleBody').each do|div|

          # fix up links
          (div/'a').each do|anchor|
            href = (anchor['href']||"")
            if !href.match(/www.people.com/)
              href = "/#{href}" if !href.match(/^\//)
              anchor['href'] = "http://www.people.com#{href}"
            end
          end
          item.body = div.to_html
        end
      end
      puts ""
    end
  end

  # specialize the tmz feed to extract image markup
  class Tmz < Feed
    def initialize(feed_xml,type='application/rss+xml')
      super(feed_xml, type)
      @items.each do|item|
        item.authors = ['TMZ Staff'] if item.authors.first.nil?
      end
      load_images
      @items.each do|item|
        image_extract(item.body)
        fixup_image(item)
      end
    end
  private
    def load_images
      @items.each do|item|
        #puts %Q(<a href="#{item.links.first}">#{item.title}</a>\n#{item.body}\n\n)
        item.links.each do|link|
          doc = Hpricot(curb_get(link))
          found = nil
          (doc/'p.body a').each do|anchor|
            if anchor.find_element("img")
              img = anchor.at("img")
              img.swap(%Q(<img class="image_thumb" src="#{img['src']}" height="80" width="120"/>))
              item.image = anchor.to_html
              break
            end
          end
          if item.image.nil? or item.image == ""
            (doc/'p.body img').each do|img|
              item.image = %Q(<img class="image_thumb" src="#{img['src']}" height="80" width="120"/>)
              break
            end
          end
        end

      end
      puts ""
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class NewsFeedTest < Test::Unit::TestCase

    def test_atom
#      feed = News::Feed.new(File.read('atom.xml'),'application/atom+xml')
#      assert_equal("Usmagazine.com celebrity_news",feed.title)
#      feed.items.each do|item|
#        #puts %Q(<a href="#{item.links.first}">#{item.title}</a>\n#{item.body}\n\n)
#        puts item.authors.inspect
#      end
    end

    def test_rss
      feed = News::Tmz.new(File.read('rss.xml'))
      assert_equal("TMZ.com",feed.title)
      assert_equal("TMZ.com",feed.subtitle)
      assert_not_nil feed.links.first
      feed.items.each do|item|
        assert_not_nil item.authors.first
        assert_not_nil item.title
        assert_not_nil item.links.first
        assert_not_nil item.body
        assert_not_nil item.published
        assert_not_nil item.summary
      end
    end

  end
end

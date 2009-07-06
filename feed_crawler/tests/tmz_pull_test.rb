require 'rubygems'
require 'test/unit'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'xml/parse_reader'
require 'feed'
require 'crawl'

DIR_ROOT=File.expand_path(File.join(File.dirname(__FILE__),'..','..') )

class TmzPullTest < Test::Unit::TestCase
  def test_live
    feed = OpenStruct.new({:klass => 'Tmz',
                           :content_type => 'application+rss/xml',
                           :link => "http://www.tmz.com/rss.xml" })

    posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post|
        posts << post
      end.run
    end

  end
end

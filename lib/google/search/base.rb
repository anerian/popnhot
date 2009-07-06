require 'rubygems'
require 'curb'
require 'json'

module Google
  module Search
    class Base
      def initialize(referer = 'http://www.popnhot.com/')
        @referer = referer
        @multi = Curl::Multi.new
        @res = {}
      end

    # curl -e http://www.my-ajax-site.com \
    #         'http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=Paris%20Hilton'
    #
      def query_for_index(query, index)
        search_url = "http://ajax.googleapis.com/ajax/services/search/#{index}?v=1.0&q=#{URI.escape(query)}"
        @res[search_url] = ''
 
        @multi.add(Curl::Easy.new(search_url) do|cfg|
          cfg.headers['Referer'] = @referer
          cfg.on_body{|data| @res[cfg.url] << data; data.size }
          cfg.on_success {|easy| yield(JSON.parse(@res[easy.url])) }
        end)
      end

      def run
        @multi.perform
        ObjectSpace.garbage_collect
      end
    end
  end
end
if $0 == __FILE__
  require 'test/unit'

  class TestBase < Test::Unit::TestCase
    def test_base
      timer = Time.now
      bs = Google::Search::Base.new
      bs.query_for_index('Paris Hilton','video') do|res|
        puts res.inspect
      end
      bs.query_for_index('Britney Spires','video') do|res|
        puts res.inspect
      end
      bs.run
      puts "multi => #{Time.now - timer} seconds"
      ObjectSpace.garbage_collect

    end
  end
end

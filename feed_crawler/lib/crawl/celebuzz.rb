module Crawl
  class Celebuzz < Crawl::Extract
    def extract(body,uri,item_content=nil)
      doc = Hpricot(body)
      body = doc.at('div.story-body')
      body = doc.at('div.story-item') unless body
      body = doc.at('#storyBody') unless body
      body = (doc/'body') unless body

      (body/"style").remove

      (body/"script").remove

      (body/"noscript").remove

      img = body.at("div.lead-img img")
      if img
        thumb_path = img['src']
      else
        # check description text
        desc = (Hpricot("<html><body>#{item_content[:description]}</body></html>")/'body')
        img = desc.at('img')
        if img
          thumb_path = img['src']
        end
      end
      return {:body => normalize(body.inner_html), :thumb_path => thumb_path }
    rescue => e
      error "In #{__FILE__}:#{__LINE__} #{e.message}\n#{e.backtrace}"
      return {:body => normalize(body), :thumb_path => thumb_path }
    end

    def filter(key,value,item)
      case key
        when :category
          return [] # remove so we use the tagger later
        when :description
          body = (Hpricot("<html><body>#{value}</body></html>")/'body')
          (body/"img").remove
          # remove br tags
          (body/"br").remove

          # remove scripts
          (body/"script").remove
          return normalize(body.inner_html)
      end
      return value
    end

  end

end

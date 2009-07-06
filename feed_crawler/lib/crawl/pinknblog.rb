require 'hpricot'

module Crawl
  class PinknBlog < Extract
    def extract(body,uri,item_content={})
      doc = Hpricot(body)
      body = doc.at('.entry')
      body = doc.at('body') unless body
      (body/"style").remove
      (body/"script").remove
      (body/"noscript").remove
        
      # check description text
      desc = (Hpricot("<html><body>#{item_content[:description]}</body></html>")/'body')
      img = desc.at('img')
      video = false
      if img
        thumb_path = img['src']
      else
        if body.at('object')
          video = true
        end
      end
      (body/"object").remove

      return {:body => normalize(body.inner_html), :thumb_path => thumb_path, :video => true }
    end
    def filter(key,value,item)
      case key
      when :description
        body = (Hpricot("<html><body>#{value}</body></html>")/'body')
        (body/"img").remove
        # remove br tags
        (body/"br").remove

        # remove scripts
        (body/"script").remove
        (body/"p").remove
        (body/"center").remove
        
        # remove objects
        (body/"object").remove

        return normalize(body.inner_html)
      else
        return value
      end
    end
  end
end

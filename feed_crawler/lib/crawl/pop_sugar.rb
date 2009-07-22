require 'hpricot'

module Crawl
  class PopSugar < Extract
    def extract(body,uri,item_content={})
      has_video = false
      thumb_path = nil
      doc = Hpricot("<html><body>#{item_content[:description]}</body></html>")
      body = doc.at("body")
      begin
        img = doc.at('img.inline')
        thumb_path = img['src'] if img
        if !thumb_path
          (doc/'img').each do|img|
            thumb_path = img['src'] if img['src'] and
                                       (img['src'].match(/media.onsugar.com/) or
                                       (img['src'].match(/images.teamsugar.com/) and (img["width"]||"0").to_i > 200))
            break if thumb_path
          end
        end
      rescue Object => e
        puts e.message
      end
      # remove br tags
      (body/"br").remove
      (doc/'img').remove
      #(body/"p").each { |p| p.swap('') if p.inner_html.strip.empty? }
      (body/"style").remove
      (body/"script").remove

      body = normalize(body.inner_html)
      {:body => body, :thumb_path => thumb_path, :video => has_video}
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

          # remove scripts
          (body/"noscript").remove

          return normalize(body.inner_html)
        else
          return value
      end
    end

  end
end

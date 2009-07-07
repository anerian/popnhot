module Crawl
  class UsMag < Extract
    def extract(body,uri,item_content={})
      has_video = false
      thumb_path = nil
      doc = Hpricot(body)

      body = doc.at('div.blog_block')
      body = doc.at('body') unless body

      (body/'span.blog_header').remove
      (body/'span.blogdatetext').remove
      img = body.at('div.img_container div img')
      thumb_path = img['src'] if img
      (body/'div.img_container').remove

      # remove br tags
      (body/"br").remove
 
      # remove scripts
      (body/"script").remove

      # detect video
      if body.at('object')
        has_video = true
      end
 
      # finally strip empty tags
      body = normalize(body.inner_html)

      {:body => body, :thumb_path => thumb_path, :video => has_video}
    end

    def filter(key, value,item)
      case key
        when :link
          begin
            uri = URI.parse(value)
            url = "http://www.usmagazine.com/#{uri.path}"
            url += "?#{uri.query}" if uri.query
            url
          rescue => e
            value.gsub(/http:\/\/.*\//,'http://www.usmagazine.com/')
          end
        when :description
          value.gsub(/&lt;/,'<').gsub(/&gt;/,'>').gsub(/&amp;/,'&')
        else
          value
      end
    end
  end
end

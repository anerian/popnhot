module Crawl
  class Eonline < Crawl::Extract
    def extract(body,uri,item_content=nil)
      doc = Hpricot(body)
      body = doc.at('div#content div.entry_content')
      body = (doc/'body') unless body

      (body/"style").remove
      (body/"script").remove
      (body/"noscript").remove
      (body/".blog_gallery").remove

      img = (body.at("div.entry_img_left img") || body.at("div.entry_img_top img") || body.at("div.entry_img_right img"))
      if img
        thumb_path = img['src']
      else
        # check for video
        if body.at("div.video_placeholder") or body.at("a.in_blog_video")
          has_video = true
        else # check for youtube
          obj = body.at('object')
          has_video = true if obj
        end
      end
      {:body => normalize(body.inner_html), :thumb_path => thumb_path, :video => has_video }
    end
    
    def filter(key,value,item)
      case key
        when :author
          return 'E! Online'
        when :description
          body = (Hpricot("<html><body>#{value}</body></html>")/'body')
          (body/"img").remove
          # remove br tags
          (body/"br").remove

          # remove scripts
          (body/"script").remove

          return normalize(body.inner_html)
      end
      value
    end
  end
end

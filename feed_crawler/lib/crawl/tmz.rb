require 'hpricot'

module Crawl
  class Tmz < Extract
    def extract(body,uri,item_content={})
      has_video = false
      thumb_path = nil
      doc = Hpricot(body)
      pbody = (doc/"p.body")
      if pbody.empty?
        body = (doc/'body')
      else
        body = pbody

        # check for img lead
        (body/"img").each do|img|
          if thumb_path.nil? and img["src"]
            thumb_path = img["src"]
          end
          #img.swap('') rescue nil
        end
        (body/"img").remove
      end
 
      # remove br tags
      (body/"br").remove
 
      # check for video
      (body/"script").each do|script|
        has_video = true if script.inner_html.match(/insertBCSinglePlayer/)
      end
      (body/"script").remove

      # finally strip empty tags
      body = normalize(body.inner_html)
      {:body => body, :thumb_path => thumb_path, :video => has_video}
    end
  end
end

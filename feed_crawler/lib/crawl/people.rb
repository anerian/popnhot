module Crawl
  class People < Extract
    def extract(body,uri,item_content=nil)
      doc = Hpricot(body)
      body = (doc/'div.articleBody')
      body = (doc/'body') unless body

      (body/"style").remove
      (body/"script").remove
      (body/"noscript").remove

      (body/".related_text").remove
      (body/".quigo").remove

      thumb_path = (item_content[:image] || item_content[:thumbnail]).first if (item_content[:image] or item_content[:thumbnail])
      {:body => normalize(body.inner_html), :thumb_path => thumb_path }
    end

    def filter(key,value,item)
      case key
        when :category
          if value.size == 1
            return value.first.split(/,/).map{|k| k.strip}
          else
            return value
          end
        when :author
          return 'People'
        when :description
          body = (Hpricot("<html><body>#{value}</body></html>")/'body')
          (body/"img").remove
          # remove br tags
          (body/"br").remove

          # remove scripts
          (body/"script").remove

          return normalize(body.inner_html)
        else
          return value
      end
    end
  end
end

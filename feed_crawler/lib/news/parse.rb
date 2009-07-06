# from http://snippets.dzone.com/posts/show/68
require 'rexml/document'

module News
  class Parse
    def self.extract( content )
      xml = REXML::Document.new(content)
      data = {}
      data[:title] = xml.root.elements['channel/title'].text
      data[:home_url] = xml.root.elements['channel/link'].text
      data[:description] = xml.root.elements['channel/description'].text
      data[:items] = []
      xml.elements.each('//item') do |item|
        it = {}
        it[:title] = item.elements['title'].text
        it[:link] = item.elements['link'].text
        it[:description] = item.elements['description'].text
        if item.elements['dc:creator']
          it[:author] = item.elements['dc:creator'].text
        end
        if item.elements['dc:date']
          it[:publication_date] = item.elements['dc:date'].text
        elsif item.elements['pubDate']
          it[:publication_date] = item.elements['pubDate'].text
        end
        data[:items] << OpenStruct.new(it)
      end
      OpenStruct.new(data)
    end
  end
end

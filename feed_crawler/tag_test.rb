CUR_DIR=File.expand_path(File.dirname(__FILE__))
LOG_DIR=File.expand_path(File.join(CUR_DIR,'log'))
DIR_ROOT=File.expand_path(File.join(CUR_DIR,'..'))

$:.unshift File.join(CUR_DIR,'lib')
require 'merb_startup'

DIR_ROOT=File.join(CUR_DIR,'..') unless defined?(DIR_ROOT)
LOG_DIR=File.join(CUR_DIR,'log') unless defined?(LOG_DIR)
  
# startup the merb environment
Merb.load_externally(DIR_ROOT)

require 'rbtagger'


tagger = Word::Tagger.new( Tag.find(:all).map{|t| t.name}, :words => 4 )

Feed.find(:all).each do|f|

  f.posts.each do|p|
    tag_list = []
    if p.tag_list.empty?
      tags = tagger.execute( "#{p.title} #{p.summary}".gsub(/[^\w]/,' ').downcase )
      if tags 
        tag_list = tags
        if tags.size > 3
          tag_list = tags.select do|t|
            tag = Tag.find_by_name(t)
            tag.name? if tag
          end
          if tag_list.size > 3
            tag_list = tag_list[0..3]
          end
        end
      end
      puts "#{tags.inspect} => #{tag_list.inspect}"
      #if tags.blank?
      #  puts "#{p.title} #{p.summary}"
      #end
    end
  end

end

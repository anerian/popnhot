class AutotagMigration < ActiveRecord::Migration
  def self.up
    require 'rbtagger'

    Tag.create( :name => 'gillian anderson' )
    Tag.create( :name => 'david duchovny' )
    Tag.create( :name => 'sarah silverman' )
    Tag.create( :name => 'stephanie pratt' )
    Tag.create( :name => 'mark wahlberg' )

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
            p.tag_list = tag_list
            p.save
          end
          puts "#{tags.inspect} => #{tag_list.inspect}"
          #if tags.blank?
          #  puts "#{p.title} #{p.summary}"
          #end
        end
      end

    end
  end

  def self.down
  end
end

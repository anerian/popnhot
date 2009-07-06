class NormalizeExistingTagsMigration < ActiveRecord::Migration
  def self.up
    Post.find(:all).each do|p|
      next if p.tag_list.blank?
      list = p.tag_list.split(',').flatten
      nlist = list.map{|t| Normalize::Tags.normalize(t) }.flatten.uniq
      puts "#{nlist.inspect} <= #{(list-nlist).inspect}"
      p.tag_list.remove((list-nlist))
      p.tag_list = nlist
      p.save
    end
    Tag.destroy_unused = true
    Tag.find(:all).each do|t|
      t.name = Normalize::Tags.normalize(t.name)
      if t.save
      else
        t.destroy
      end
    end
  end

  def self.down
  end
end

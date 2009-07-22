class CreateHotTags < ActiveRecord::Migration
  def self.up
    create_table :hot_tags do |t|
      t.string :tag_id_list
      t.timestamps
    end
  end

  def self.down
    drop_table :hot_tags
  end
end

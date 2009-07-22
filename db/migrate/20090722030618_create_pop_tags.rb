class CreatePopTags < ActiveRecord::Migration
  def self.up
    create_table :pop_tags do |t|
      t.string :tag_id_list
      t.timestamps
    end
  end

  def self.down
    drop_table :pop_tags
  end
end

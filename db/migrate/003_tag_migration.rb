class TagMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string  :name,    :null => false
      t.integer :user_id
      t.timestamps
    end 

    add_index "tags", ["name"], :name => "name_index", :unique => true
    add_index "tags", ["user_id"], :name => "fk_labels_user_id_to_users_id"

    create_table :taggings do|t|
      t.integer  :tag_id
      t.integer  :taggable_id
      t.string   :taggable_type
      t.timestamps
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"
  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end

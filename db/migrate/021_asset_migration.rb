class AssetMigration < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.string   "filename"
      t.string   "description"
      t.integer  "post_id"
      t.string   "content_type"
      t.integer  "size"
      t.integer  "parent_id"
      t.string   "thumbnail"
      t.integer  "width"
      t.integer  "height"
      t.string   "title"
      t.string   "source"
      t.timestamps
    end 
    add_index :assets, :title
    add_index :assets, :updated_at
    add_index :assets, :post_id
  end

  def self.down
    drop_table :assets
  end
end

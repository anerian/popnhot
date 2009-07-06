class CacheTagListColumnMigration < ActiveRecord::Migration
  def self.up
    add_column :posts, :cached_tag_list, :string, :limit => 512
  end

  def self.down
    remove_column :posts, :cached_tag_list
  end
end

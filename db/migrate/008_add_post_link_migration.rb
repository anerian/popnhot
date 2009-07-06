class AddPostLinkMigration < ActiveRecord::Migration
  def self.up
    add_column :posts, :link, :string, :limit => 1024
  end

  def self.down
    remove_column :posts, :link
  end
end

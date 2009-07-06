class AddIndexToPermalinkMigration < ActiveRecord::Migration
  def self.up
    add_index :posts, :permalink
  end

  def self.down
    remove_index :posts, :permalink
  end
end

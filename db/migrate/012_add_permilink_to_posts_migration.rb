class AddPermilinkToPostsMigration < ActiveRecord::Migration
  def self.up
    add_column :posts, :permalink, :string, :default => '', :null => false
  end

  def self.down
    remove_column :posts, :permalink
  end
end

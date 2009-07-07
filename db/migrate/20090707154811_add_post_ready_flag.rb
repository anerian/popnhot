class AddPostReadyFlag < ActiveRecord::Migration
  def self.up
    add_column :posts, :ready, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :posts, :ready
  end
end

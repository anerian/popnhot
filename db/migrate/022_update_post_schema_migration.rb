class UpdatePostSchemaMigration < ActiveRecord::Migration
  def self.up
    change_column :posts, :summary, :text, :default => '', :null => false
    change_column :posts, :link, :string, :limit => 1024,:default => '',  :null => false
    change_column :posts, :feed_id, :integer, :default => 0,  :null => false
  end

  def self.down
    change_column :posts, :summary, :string, :limit => 1024
  end
end

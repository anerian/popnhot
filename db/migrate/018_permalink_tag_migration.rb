class PermalinkTagMigration < ActiveRecord::Migration
  def self.up
    add_column :tags, :permalink, :string, :default => '', :null => false
    add_index :tags, :permalink
    Tag.find(:all).each{|t| t.save!}
  end

  def self.down
    remove_column :tags, :permalink
  end
end

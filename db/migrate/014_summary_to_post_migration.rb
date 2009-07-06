class SummaryToPostMigration < ActiveRecord::Migration
  def self.up
    add_column :posts, :summary, :string, :limit => 1024
  end

  def self.down
    remove_column :posts, :summary
  end
end

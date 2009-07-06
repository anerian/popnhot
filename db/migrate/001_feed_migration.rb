class FeedMigration < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title, :null => false
      t.string :link, :null => false
      t.string :subtitle
      t.timestamps
    end 
  end

  def self.down
    drop_table :feeds
  end
end

class AddFeedClassTypeNotStiMigration < ActiveRecord::Migration
  def self.up
    add_column :feeds, :feed_type, :string
  end

  def self.down
    remove_column :feeds, :feed_type
  end
end

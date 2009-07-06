class FeedsNeedTheOriginalFeedXmlMigration < ActiveRecord::Migration
  def self.up
    add_column :feeds, :feed_url, :string
  end

  def self.down
    remove_column :feeds, :feed_url
  end
end

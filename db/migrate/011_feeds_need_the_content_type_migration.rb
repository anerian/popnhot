class FeedsNeedTheContentTypeMigration < ActiveRecord::Migration
  def self.up
    add_column :feeds, :content_type, :string, :default => 'application/rss+xml', :null => false
    rename_column :feeds, :feed_url, :url
    rename_column :feeds, :feed_type, :klass
  end

  def self.down
    remove_column :feeds, :content_type
    rename_column :feeds, :url, :feed_url
    rename_column :feeds, :klass, :feed_type
  end
end

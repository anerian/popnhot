class PostBelongsToFeedMigration < ActiveRecord::Migration
  def self.up
    add_column :posts, :feed_id, :integer
    add_index "posts", ["feed_id"], :name => "index_posts_on_feed_id"
  end

  def self.down
    remove_column :posts, :feed_id
  end
end

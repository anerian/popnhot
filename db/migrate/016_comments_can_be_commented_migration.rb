class CommentsCanBeCommentedMigration < ActiveRecord::Migration
  def self.up
    add_column :comments, :comment_id, :integer
  end

  def self.down
    remove_column :comments, :comment_id
  end
end

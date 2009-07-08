class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.string :focus
      t.string :words
      t.timestamps
    end
    create_table :posts_topics, :id => false do |t|
      t.integer :post_id, :null => false
      t.integer :topic_id, :null => false
    end
    add_index :posts_topics, [:topic_id, :post_id]
  end

  def self.down
    drop_table :topics
    drop_table :posts_topics
  end
end

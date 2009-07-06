class PostMigration < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.string :title, :null => false
      t.string :image, :limit => 1024
      t.text :body, :null => false
      t.string :author
      t.timestamps
    end 
  end

  def self.down
    drop_table :posts
  end
end

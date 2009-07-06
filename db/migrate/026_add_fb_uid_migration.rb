class AddFbUidMigration < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_uid, :integer
  end

  def self.down
    remove_column :users, :fb_uid
  end
end

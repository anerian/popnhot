class UserAddName < ActiveRecord::Migration
  def self.up
    add_column :users, :name, :string, :default => 'unknown', :null => false
    add_index :users, :name, :unique => true
  end

  def self.down
    drop_table :users
  end
end

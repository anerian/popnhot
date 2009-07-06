class UserMigration < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string   :email,                  :limit => 128, :null => false
      t.string   :hashed_password,        :limit => 40,  :null => false
      t.string   :salt,                                  :null => false
      t.string   :remember_token
      t.datetime :remember_token_expires
      t.timestamps
    end 
    add_index :users, :email, :unique => true
  end

  def self.down
    drop_table :users
  end
end

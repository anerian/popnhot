class SphinxDeltaIndexMigration < ActiveRecord::Migration
  def self.up

    create_table "indexer_status" do |t|
      t.string   "index_name", :limit => 50
      t.datetime "updated_at"
      t.string   "status"
      t.datetime "started_at"
      t.string   "hostname"
    end

    add_index "indexer_status", ["hostname", "index_name"], :name => "index_indexer_status_on_hostname_and_index_name", :unique => true
  end

  def self.down
    drop_table :indexer_status
  end
end

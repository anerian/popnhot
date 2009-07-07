# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090707154811) do

  create_table "assets", :force => true do |t|
    t.string   "filename"
    t.string   "description"
    t.integer  "post_id"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.integer  "width"
    t.integer  "height"
    t.string   "title"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assets", ["post_id"], :name => "index_assets_on_post_id"
  add_index "assets", ["title"], :name => "index_assets_on_title"
  add_index "assets", ["updated_at"], :name => "index_assets_on_updated_at"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "post_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "comment_id"
  end

  create_table "feeds", :force => true do |t|
    t.string   "title",                                           :null => false
    t.string   "link",                                            :null => false
    t.string   "subtitle"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "klass"
    t.string   "url"
    t.string   "content_type", :default => "application/rss+xml", :null => false
  end

  create_table "indexer_status", :force => true do |t|
    t.string   "index_name", :limit => 50
    t.datetime "updated_at"
    t.string   "status"
    t.datetime "started_at"
    t.string   "hostname"
  end

  add_index "indexer_status", ["hostname", "index_name"], :name => "index_indexer_status_on_hostname_and_index_name", :unique => true

  create_table "posts", :force => true do |t|
    t.string   "title",                                              :null => false
    t.string   "image",           :limit => 1024
    t.text     "body",                                               :null => false
    t.string   "author"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feed_id",                         :default => 0,     :null => false
    t.datetime "published_at"
    t.string   "link",            :limit => 1024, :default => "",    :null => false
    t.string   "permalink",                       :default => "",    :null => false
    t.text     "summary",         :limit => 1024, :default => "",    :null => false
    t.string   "cached_tag_list", :limit => 512
    t.boolean  "ready",                           :default => false, :null => false
  end

  add_index "posts", ["feed_id"], :name => "index_posts_on_feed_id"
  add_index "posts", ["permalink"], :name => "index_posts_on_permalink"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string   "name",                       :null => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "permalink",  :default => "", :null => false
  end

  add_index "tags", ["name"], :name => "name_index", :unique => true
  add_index "tags", ["permalink"], :name => "index_tags_on_permalink"
  add_index "tags", ["user_id"], :name => "fk_labels_user_id_to_users_id"

  create_table "users", :force => true do |t|
    t.string   "email",                  :limit => 128,                        :null => false
    t.string   "hashed_password",        :limit => 40,                         :null => false
    t.string   "salt",                                                         :null => false
    t.string   "remember_token"
    t.datetime "remember_token_expires"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                                  :default => "unknown", :null => false
    t.integer  "fb_uid"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name", :unique => true

end

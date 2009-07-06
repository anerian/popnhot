# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_popnhot-rails_session',
  :secret      => '5e0e42c804b35657582c847ab114a463162a34b23162344132280dae4f55ecb5853c0598cd23d3f2b31c5a829a05dfe5067b987eecb26c6729021afe2c33859b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

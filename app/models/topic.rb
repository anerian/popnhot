class Topic < ActiveRecord::Base
  named_scope :created_after, lambda {|date| {:conditions => ["created_on > ?", date]} }
end

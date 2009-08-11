class Topic < ActiveRecord::Base
  named_scope :created_after, lambda {|date| {:conditions => ["created_on > ?", date]} }
  def count
    Post.search(self.query, :match_mode => :any).length
  end
  
  class << self
    
  end
end

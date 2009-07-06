class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  belongs_to :comment
  has_many :comments, :dependent => :destroy

  validates_presence_of  :message, :post_id, :user_id
end

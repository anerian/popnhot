class Topic < ActiveRecord::Base
  serialize :words
  has_and_belongs_to_many :posts
end

#!/usr/bin/env ruby
# Determine hotness using tags
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 
require 'lib/dist.all.first'
require 'lib/dist.all.last'

# TODO: we need to do some sort of normalization of the distribution of tag counts
# and make this a normalized number eventually everyone will be popular
pop_tags = Post.tag_counts( :at_least => 4, :limit => 40, :order => 'count desc' )
pop_tags = pop_tags.select{|t| t.name? }.sort_by{|t| t.count }.reverse

if pop_tags
  pop_tags = pop_tags[0..20]
  popular = PopTag.first
  if !popular
    PopTag.create :tag_id_list => pop_tags.map{|t| t.id}
  else
    popular.tag_id_list = pop_tags.map{|t| t.id}
    popular.save!
  end
end

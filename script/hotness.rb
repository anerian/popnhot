#!/usr/bin/env ruby
# Determine hotness using tags
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 

# determine the post with the most tags within the first 5
#posts = @posts.select{|p| p.tag_list.length > 2}.sort_by{|p| p.tag_list.length }.reverse
#if !posts.empty? and !posts.first.nil?
hot_tags = Post.tag_counts( :start_at => 1.day.ago, :at_least => 2 )
hot_tags = hot_tags.select{|t| t.name? }.sort_by{|t| t.count }.reverse
if hot_tags.empty?
  hot_tags = Post.tag_counts( :start_at => 1.day.ago, :at_least => 1 )
  hot_tags = hot_tags.select{|t| t.name? }.sort_by{|t| t.count }.reverse
  if hot_tags.empty?
    hot_tags = Post.tag_counts( :start_at => 2.day.ago, :at_least => 1 )
    hot_tags = hot_tags.select{|t| t.name? }.sort_by{|t| t.count }.reverse
  end
end
if hot_tags
  # take the top 10 tags
  hot_tags = hot_tags[0..10]
  hotness = HotTag.first
  if !hotness
    HotTag.create :tag_id_list => hot_tags.map{|t| t.id }
  else
    hotness.tag_id_list = hot_tags.map{|t| t.id }
    hotness.save!
  end
end

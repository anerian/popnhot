#!/usr/bin/env ruby
# Cluster Recent posts by topic
# Take the last day's worth of posts and determine the topic clusters
require File.join(File.dirname(__FILE__),'..','config','environment')
require 'lda'

tags = Tag.all.map{|t| t.name }
puts tags.inspect
posts = Post.find(:all, :limit => 100, :order => 'created_at DESC')
puts posts.size

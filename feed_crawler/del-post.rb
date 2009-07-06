CUR_DIR=File.expand_path(File.dirname(__FILE__))
LOG_DIR=File.expand_path(File.join(CUR_DIR,'log'))
DIR_ROOT=File.expand_path(File.join(CUR_DIR,'..'))

$:.unshift File.join(CUR_DIR,'lib')
require 'merb_startup'

DIR_ROOT=File.join(CUR_DIR,'..') unless defined?(DIR_ROOT)
LOG_DIR=File.join(CUR_DIR,'log') unless defined?(LOG_DIR)
  
# startup the merb environment
Merb.load_externally(DIR_ROOT)
    
require 'crawl'
require 'delicious_post'

post = Post.find_by_permalink("miley-cyrus-lookin-for-a-boyfriend")
puts post.tag_list.to_s.gsub(/,/,' ').inspect
dpost = DeliciousPost.new( post )
dpost.add


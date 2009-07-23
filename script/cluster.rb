#!/usr/bin/env ruby
# Cluster Recent posts by topic
# Take the last day's worth of posts and determine the topic clusters
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 
require 'lda'
require 'rbtagger'
require File.join(RAILS_ROOT,'lib','normalize_tags')

def post_text(post)
  Normalize::Tags.prune_stopwords(post.title) + ' ' + post.tag_list.join(' ') #post.title + ' ' + post.body
end

class PostDoc < Lda::Document
  def initialize(post, vocab_set, tagger)
    text = post_text(post)
    puts "Using text: #{text}"
    term_freq = tagger.freq(text)
    idx = "#{term_freq.size} "
    @post = post
    # see: lda-ruby/lib/lda.rb: 66
    # build svmlight-style text line: 
    #   num_words w1:freq1 w2:freq2 ... w_n:freq_n
    # Ex.
    #   5 1:2 3:1 4:2 7:3 12:1
    #
    term_freq.each {|w,f| idx += "#{vocab_set[w]}:#{f} " }
    super(idx)
  end
end

def build_vocab(posts)
  vec = []  #Tag.all.map{|t| t.name }
  posts.each {|p| vec << post_text(p).split(' ') }
  vec.flatten!
  vec.uniq!
  puts "Vocab size: #{vec.size}"
  set = {}
  vec.each_with_index {|w,i| set[w] = i } # so we can quickly look up term index
  [vec, set]
end

Topic.destroy_all

# find the last 100 posts
posts = Post.find(:all, :limit => 140, :order => 'created_at DESC')

# build the vocabulary from the tags
vocab_vec, vocab_set = build_vocab(posts)

# create the tagger
tagger = Word::Tagger.new( vocab_vec, :words => 4 )

corpus = Lda::Corpus.new
docs = []
for post in posts do
  doc = PostDoc.new(post, vocab_set, tagger)
  corpus.add_document(doc)
  docs << doc
end

model = Lda::Lda.new
model.num_topics = 10
#model.max_iter = 200
corpus.instance_variable_set(:@num_terms,vocab_vec.size)
model.corpus = corpus
puts "running EM seeded"
model.em("seeded")
model.load_vocabulary(vocab_vec)
#puts model.to_s
#puts "doc prob: #{model.compute_topic_document_probability.inspect}"
#puts "doc phi: #{model.phi.inspect}"
#puts "--------"
topics = model.top_words
updated_topics = []
topics.each do|id,words|
  puts "#{words.inspect}"
  focus = words.first
  topic = Topic.find_or_create_by_focus( :focus => focus, :words => words )
  regtags = words.join('|')
  selected = posts.select{|p| p.title.match(regtags) }
  if selected.empty?
    if topic.posts.empty?
      topic.destroy
    end
  else
    #posts -= selected
    posts = posts.reject{|p| selected.find{|i| i.id == p.id} }
    topic.posts = selected
    puts "Adding #{topic.posts.size}"
    puts "created topic: #{topic.focus} with Posts, #{topic.posts.map{|p| p.title}.inspect}"
    topic.save!
    updated_topics << topic
  end
  puts "posts left: #{posts.size}"
end
puts "posts left: #{posts.size}"
topic = Topic.find_or_create_by_focus( :focus => 'other')
topic.posts = posts
topic.save!
puts "all topics created"

# now let's scan all the created topics
# 

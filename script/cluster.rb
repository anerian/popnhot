#!/usr/bin/env ruby
# Cluster Recent posts by topic
# Take the last day's worth of posts and determine the topic clusters
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 
require 'lda'
require 'rbtagger'

def create_document(post,vocab_set,tagger)
  text = post.title + ' ' + post.body
  term_freq = tagger.freq(text)
  idx = "#{term_freq.size} "
  # see: lda-ruby/lib/lda.rb: 66
  # build svmlight-style text line: 
  #   num_words w1:freq1 w2:freq2 ... w_n:freq_n
  # Ex.
  #   5 1:2 3:1 4:2 7:3 12:1
  #
  term_freq.each {|w,f| idx += "#{vocab_set[w]}:#{f} " }
  Lda::Document.new(idx)
end

def build_vocab
  vec = Tag.all.map{|t| t.name }
  set = {}
  vec.each_with_index {|w,i| set[w] = i } # so we can quickly look up term index
  [vec, set]
end

# build the vocabulary from the tags
vocab_vec, vocab_set = build_vocab

# create the tagger
tagger = Word::Tagger.new( vocab_vec, :words => 4 )

posts = Post.find(:all, :limit => 100, :order => 'created_at DESC')
corpus = Lda::Corpus.new
for post in posts do
  doc = create_document(post, vocab_set, tagger)
  corpus.add_document(doc)
end
model = Lda::Lda.new
model.corpus = corpus
model.em("random")
model.load_vocabulary(vocab_vec)
puts model.to_s
puts "doc prob: #{model.compute_topic_document_probability.inspect}"
puts "doc phi: #{model.phi.inspect}"
puts "--------"
#model.print_topics
puts model.top_words.inspect

#!/usr/bin/env ruby
# Cluster Recent posts by topic
# Take the last day's worth of posts and determine the topic clusters
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 
require 'lda'
require 'rbtagger'

class PostDoc < Lda::Document
  def initialize(post, vocab_set, tagger)
    text = post.title + ' ' + post.body
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
  vec = Tag.all.map{|t| t.name }
  posts.each {|p| vec << p.plain_text.split(' ') }
  vec.flatten!
  vec.uniq!
  puts "Vocab size: #{vec.size}"
  set = {}
  vec.each_with_index {|w,i| set[w] = i } # so we can quickly look up term index
  [vec, set]
end

# all posts
posts = Post.find(:all, :limit => 100, :order => 'created_at DESC')

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
model.corpus = corpus
puts "running EM seeded"
model.em("seeded")
model.load_vocabulary(vocab_vec)
#puts model.to_s
#puts "doc prob: #{model.compute_topic_document_probability.inspect}"
#puts "doc phi: #{model.phi.inspect}"
puts "--------"
#model.print_topics
topics = model.top_words
topics.each do|id,words|
  #puts "#{vocab_vec[id]} -> #{words.inspect}"
  focus = vocab_vec[id]
  topic = Topic.find_or_create_by_focus( :focus => focus, :words => words )
  topic.posts = posts.select{|p|
    text = p.plain_text
    if text.match(focus) 
      true
    else
      ret = false
      for w in words do
        if text.match(w)
          ret = true
          break
        end
      end
      ret
    end
  }
  puts "created topic: #{topic.focus} with Posts, #{topic.posts.map{|p| p.title}.inspect}"
end
puts "all topics created"

#!/usr/bin/env ruby
# Cluster Recent posts by topic
# Take the last day's worth of posts and determine the topic clusters
require File.join(File.dirname(__FILE__),'..','config','environment')
$:.unshift File.join(RAILS_ROOT,'lda-ruby','lib') 
require 'lda'
require 'rbtagger'
require File.join(RAILS_ROOT,'lib','normalize_tags')

class Text
  PRUNE=(Post.excluded_tags + ['INSIDE STORY:','PHOTO GALLERY:','VIDEO:','POLL:','SYTYCD:','UPDATE:']).freeze

  def self.post_text(post,tagger=nil)
    title = post.title
    PRUNE.each {|p| title.gsub!(p,'') } # remove common no-op words
    text = Normalize::Tags.prune_stopwords(title) + ' ' + post.tag_list.join(' ') + ' ' + Normalize::Tags.prune_stopwords(post.plain_text) 
    text = Normalize::Tags.prepare_text(text)
    if tagger
      tagger.nouns(text).map{|t| t.first.stem.downcase }.join(' ')
    else
      text.downcase
    end
#    post.tag_list.join(' ')
  end
end

class Model < Lda::Lda
  def initialize(corpus)
    super()
    @corpus = corpus
    self.num_topics = (corpus.posts.size/2)
    self.max_iter = 200
    self.corpus = corpus
    self.load_vocabulary(corpus.vocab_vec)
  end

  def cluster
    discover_topics
    doc_prob = self.compute_topic_document_probability
    topics = self.top_words
    puts topics.inspect
  end

protected
  def discover_topics
    self.em("random")
  end
end

class Corpus < Lda::Corpus
  attr_reader :posts, :docs, :tagger, :vocab_vec, :vocab_set

  def initialize
    super

    @rule_tagger = Brill::Tagger.new

    # find the last 100 posts
    @posts = Post.find(:all, :limit => Post.count, :order => 'created_at DESC')

    # build the vocabulary from the tags
    build_vocab

    # create the tagger
    @tagger = Word::Tagger.new( @vocab_vec, :words => 4 )

    @docs = []
    for post in @posts do
      doc = PostDoc.new(post, @vocab_set, @tagger, @rule_tagger)
      self.add_document(doc)
      @docs << doc
    end
    @num_terms = @vocab_vec.size # make sure we allocate a large enough term space
    self.instance_variable_set(:@num_terms,@vocab_vec.size)

  end

  def model
    @model ||= Model.new(self)
  end

  def doc_freq_by_term(term)
  end

protected
  def build_vocab
    vec = []  #Tag.all.map{|t| t.name }
    @posts.each {|p| vec << Text::post_text(p, @rule_tagger).split(' ') }
    vec.flatten!
    vec.uniq!
    puts "Vocab size: #{vec.size}"
    set = {}
    vec.each_with_index {|w,i| set[w] = i } # so we can quickly look up term index
    @vocab_vec = vec
    @vocab_set = set
  end

end

class PostDoc < Lda::Document
  def initialize(post, vocab_set, tagger, rtagger)
    text = Text::post_text(post,rtagger)
    @term_freq = tagger.freq(text)
    puts @term_freq.inspect
    idx = "#{@term_freq.size} "
    @post = post
    # see: lda-ruby/lib/lda.rb: 66
    # build svmlight-style text line: 
    #   num_words w1:freq1 w2:freq2 ... w_n:freq_n
    # Ex.
    #   5 1:2 3:1 4:2 7:3 12:1
    #
    @term_freq.each {|w,f| idx += "#{vocab_set[w]}:#{f} " }
    super(idx)
  end

  # see: http://oldmoe.blogspot.com/2008/08/document-matching-in-ruby.html
  def tf_idf(corpus)
    total_frequency = @term_freq.values.inject(0){|a,b|a+b}
    @term_freq.each do |term,freq|
      @term_freq[term] = (freq / total_frequency) * self.df(term) #assume we have a method that returns the document frequency value for any term
      magnitude = magnitude + (@term_freq[term]**2)
    end
    [@term_freq, magnitude]
  end

  def match(doc)
    my_tf_idf,  my_magnitude  = self.tf_idf
    his_tf_idf, his_magnitude = doc.tf_idf
    dot_product = 0
    my_tf_idf.each do |term,tf_idf|
      dot_product = dot_product + tf_idf * his_tf_idf[term] if his_tf_idf[term]
    end
    cosine_similarity = dot_product / (my_magnitude * his_magnitude)
  end

end

Topic.destroy_all # for testing - only

# load the corpus
corpus = Corpus.new

# get the model
model = corpus.model

# cluster the documents
model.cluster do|words,docs|
  # words, describing the topic
  # docs, that fit closest to the words
  # TODO: create the topic models? or update the existing topics?
end

#model = Lda::Lda.new
#model.num_topics = (Post.count/2) # hmm... maybe half sounds good?
#model.max_iter = 200
#
#model.corpus = corpus

#model.em("random")
#model.load_vocabulary(vocab_vec)
#
#doc_prob = model.compute_topic_document_probability
#puts "doc prob of topic: #{doc_prob.size}"
#puts "--------"
#topics = model.top_words
#updated_topics = []
#topic_roots = []
#topics.each do|topic_id,words|
#  topic_roots << {:root => posts[id]}
#  puts "#{id}(#{doc_prob[id][topic_id]}): #{topic_roots.last[:root].title} -> #{words}"
#end
exit(0)

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

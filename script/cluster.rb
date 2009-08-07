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

  #
  # extract terms from post, include the month-day timestamp as a special term - since news articles are generally time based
  #
  def self.post_words(post,tagger=nil)
    # make sure we're in the same char encoding
    title = Normalize::Tags.prepare_text(post.title)
    body = Normalize::Tags.prepare_text(post.plain_text)

    # remove labels
    PRUNE.each {|p| title.gsub!(p,'') } # remove common no-op words
    PRUNE.each {|p| body.gsub!(p,'') } # remove common no-op words

    # break by sentence and space
    title = title.strip.split('.').map{|s| s.split(' ') }.flatten.join(' ')
    body = body.strip.split('.').map{|s| s.split(' ') }.flatten.join(' ')

    # extract only nouns
    title_words = tagger.nouns(title).map{|t| t.first.stem.downcase }
    body_words  = tagger.nouns(body ).map{|t| t.first.stem.downcase }

    # add the date timestamp as a tag to relate docs by time e.g. any article published on tuesday is more likely to be related then friday and tuesday...
    [post.created_at.strftime("%F")] + title_words + post.tag_list + body_words
  end
end

class Model < Lda::Lda
  def initialize(corpus)
    super()
    @corpus = corpus
    self.num_topics = (corpus.posts.size/2)
    self.max_iter = 50
    self.corpus = corpus
    self.load_vocabulary(corpus.vocab_vec)
  end

  def cluster
    discover_topics
    doc_prob = self.compute_topic_document_probability
    topics = self.top_words
    # document array with array of topics probability
    cluster = {}
    doc_prob.each_with_index do|topic_probs, doc_idx|
      doc = @corpus.posts[doc_idx]
      tp_ordered = []
      topic_probs.each_with_index do|tp,idx|
        tp_ordered << {:prob => tp.abs, :id => idx}
      end
      tp_ordered = tp_ordered.sort_by {|v| v[:prob] }
      most_likely_topic = tp_ordered.last
      # detailed inspect
      #puts "#{topics[most_likely_topic[:id]].inspect} - #{most_likely_topic[:prob]} - #{doc.title} - #{tp_ordered.inspect}"
      id = most_likely_topic[:id]
      cluster[id] ||= {}
      cluster[id][:docs] ||= []
      cluster[id][:words] ||= topics[id]
      cluster[id][:docs] << doc
      #puts "#{most_likely_topic[:id]} - #{doc.title}"
    end
#    for c in cluster do
#      yield c[:words], c[:docs]
#    end
    cluster.each do|cid,info|
      puts "cluster: #{cid}- #{info[:words].inspect}"
      info[:docs].each do|doc|
        puts "\t#{doc.title}"
      end
    end
    #puts topics.inspect
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

    puts "loading tagger lexicon..."
    @rule_tagger = Brill::Tagger.new

    puts "loading new posts..."
    # find the last 100 posts
    @posts = Post.find(:all, :limit => Post.count, :order => 'created_at DESC')

    puts "building vocabulary..."
    # build the vocabulary from the tags
    build_vocab

    # create the tagger
    @tagger = Word::Tagger.new( @vocab_vec, :words => 4 )

    puts "loading documents..."
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
    matching = @docs.select{|doc| doc.include?(term) }
    matching.count
  end

protected
  def build_vocab
    vec = []  #Tag.all.map{|t| t.name }
    @posts.each {|p| vec += Text::post_words(p, @rule_tagger) }
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
  attr_reader :term_freq
  def initialize(post, vocab_set, tagger, rtagger)
    words = Text::post_words(post,rtagger)
    @term_freq = {}#tagger.freq(text)
    for w in words do
      if @term_freq.key?(w)
        @term_freq[w] += 1
      else
        @term_freq[w] = 1
      end
    end

    #puts @term_freq.inspect
    idx = "#{@term_freq.size} "
    @post = post
    # see: lda-ruby/lib/lda.rb: 66
    # build svmlight-style text line: 
    #   num_words w1:freq1 w2:freq2 ... w_n:freq_n
    # Ex.
    #   5 1:2 3:1 4:2 7:3 12:1
    #
    @term_freq.each {|w,f| idx += "#{vocab_set[w]}:#{f} " }
    @total_frequency = @term_freq.values.inject(0){|a,b|a+b} 
    super(idx)
  end

  def include?(word)
    @term_freq.key?(word)
  end

  # see: http://oldmoe.blogspot.com/2008/08/document-matching-in-ruby.html
  def tf_idf(corpus)
    magnitude = 0
    @term_freq.each do |term,freq|
      @term_freq[term] = (freq / @total_frequency) * corpus.doc_freq_by_term(term) #assume we have a method that returns the document frequency value for any term
      magnitude += (@term_freq[term]**2)
    end
    [@term_freq, magnitude]
  end

  # see: http://oldmoe.blogspot.com/2008/08/document-matching-in-ruby.html
  def cosine_similarity(doc)
    my_tf_idf,  my_magnitude  = self.tf_idf
    his_tf_idf, his_magnitude = doc.tf_idf

    dot_product = 0
    my_tf_idf.each do |term,tf_idf|
      dot_product += (tf_idf * his_tf_idf[term]) if his_tf_idf[term]
    end

    dot_product / Math.sqrt(my_magnitude * his_magnitude)
  end

end

#XXX: removing topics for testing ONLY XXX
Topic.destroy_all # for testing - ONLY XXX
#XXX: removing topics for testing ONLY XXX

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

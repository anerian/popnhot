# After more thought this is cluster version 2
# it uses the much improved lda-ruby interface added in version 0.3
require File.expand_path(File.dirname(__FILE__)+"/../config/environment.rb")
require 'lda-ruby' # sudo gem install ealdent-lda-ruby
require File.join(RAILS_ROOT,'lib','normalize_tags')

class Text
  class Stopword
    Words = File.read(File.expand_path(File.dirname(__FILE__)+"/../config/stopwords.txt")).split("\n").map{|w| w.strip}

    def self.prune(words)
      words.reject{|w| w.size == 1 or Words.include?(w) }
    end
  end
  PRUNE=(Post.excluded_tags + ['INSIDE STORY:','PHOTO GALLERY:','VIDEO:','POLL:','SYTYCD:','UPDATE:']).freeze

  #
  # extract terms from post
  #
  def self.post_words(post)
    # make sure we're in the same char encoding
    title = Normalize::Tags.prepare_text(post.title)
    body = Normalize::Tags.prepare_text(post.plain_text)

    # remove labels
    PRUNE.each {|p| title.gsub!(p,'') } # remove common no-op words
    PRUNE.each {|p| body.gsub!(p,'') } # remove common no-op words

    # break by sentence and space
    title = title.strip.split('.').map{|s| s.split(' ') }.flatten.map{|w| w.downcase}#.join(' ')
    body = body.strip.split('.').map{|s| s.split(' ') }.flatten.map{|w| w.downcase}#.join(' ')

    #"#{title} #{body}"
    Stopword.prune(title + body)
  end
end

corpus = Lda::Corpus.new
puts "Loading Posts from the last cycle..."
posts = Post.find(:all, :limit => 100)
posts.each do|p|
  doc = Lda::TextDocument.new(corpus, Text::post_words(p).join(' '))
  corpus.add_document(doc)
end
puts "Vocab: #{corpus.documents.size} docs ad #{corpus.vocabulary.words.size} words"
# invert words index
idvwi = {}
corpus.vocabulary.words.each do|word,id|
  idvwi[id] = word
end
lda = Lda::Lda.new(corpus)
lda.em("seeded")
topics = lda.top_words(5)
Topic.destroy_all
topics.each do|t,words|
  words.map!{|wid| idvwi[wid] }
  puts "create topic: #{words.inspect}"
  Topic.create :query => words.join(" ")
end

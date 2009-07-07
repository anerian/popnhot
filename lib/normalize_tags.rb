require File.join(File.dirname(__FILE__),'dist.all.last')
require File.join(File.dirname(__FILE__),'dist.all.first')
require File.join(File.dirname(__FILE__),'dirty.words')
require 'rubygems'
require 'rbtagger'

module Normalize
  class Tags
    def self.normalize(tag)
      ns = ''
      caps=0
      tag.split('').each do|c|
        if c.match(/[A-Z]/)
          ns << " #{c}"
          caps += 1
        else
          ns << c
        end
      end
      if caps > 2 and tag.size < 7
        tag.downcase.strip.gsub(/\s+/,' ')
      else
        ns.downcase.strip.gsub(/\s+/,' ')
      end

    end

    def self.selective(tags, doc=nil)
      taglist = (Names::Last.all + Names::First.all).map{|n| n.to_s.downcase}
      tagger = Word::Tagger.new taglist, :words => 4
      result_tags = []
      for tag in tags do
        rt = tagger.execute( tag )
        result_tags << rt.join(' ') if rt.any?
      end
      if doc
        rt = tagger.execute(doc)
        if rt.any?
          result_tags += rt 
          result_tags.uniq!
        end
      end
      result_tags
    end

  end
end

if defined?(TagList)
  TagList.class_eval do
    def add(*names)
      extract_and_apply_options!(names)
      concat((names||[]).map{|n| Normalize::Tags.normalize(n) }.uniq)
      clean!
      self
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class VerifyTest < Test::Unit::TestCase
    def test_spears_kfed
      tags = ['britney spears', 'BritneySpears', 'k-fed', 'kevin federline', 'KevinFederline'].map do|t|
        Normalize::Tags.normalize(t)
      end.uniq
      assert_equal ["britney spears", "k-fed", "kevin federline"], tags
    end

    def test_guns_n_roses
      tags = ["dave  weintraub", "dave weintraub", "guns  n  roses", "guns n roses", "steven  adler", "steven adler"]
      ntags = tags.map{|t| Normalize::Tags.normalize(t) }.uniq
      assert_equal ["dave weintraub", "guns n roses", "steven adler"], ntags
    end

    def test_selective
      tags = ["dave  weintraub", "dave weintraub", "guns  n  roses", "guns n roses", "steven  adler", "steven adler"]
      ntags = tags.map{|t| Normalize::Tags.normalize(t) }.uniq
      assert_equal ["dave weintraub", "guns n roses", "steven adler"], ntags
      puts Normalize::Tags.selective(ntags).inspect
    end
  end
end

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
  end
end

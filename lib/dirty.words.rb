require 'set'
module Names
  class DirtyWord
    def self.include?(name)
      define_set unless defined?(@_dirty_words)
      @_dirty_words.each do|dw|
        return true if name.match(dw)
      end
      return false
    end
    def self.define_set
      @_dirty_words = [
/STRIP/i,
/SLUT/i
]
    end
  end
end

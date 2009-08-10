class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy, :order => 'created_at DESC'

  has_permalink :name
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def last_name 
    self.name.split(" ").last
  end
  
  def first_name
    self.name.split(" ").first
  end

  def count
    read_attribute(:count).to_i
  end
  
  class << self
    # Calculate the tag counts for all tags.
    #  :start_at - Restrict the tags to those created after a certain time
    #  :end_at - Restrict the tags to those created before a certain time
    #  :conditions - A piece of SQL conditions to add to the query
    #  :limit - The maximum number of tags to return
    #  :order - A piece of SQL to order by. Eg 'count desc' or 'taggings.created_at desc'
    #  :at_least - Exclude tags with a frequency less than the given value
    #  :at_most - Exclude tags with a frequency greater than the given value
    def counts(options = {})
      find(:all, options_for_counts(options))
    end
    
    def options_for_counts(options = {})
      options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :joins
      options = options.dup
      
      start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
      end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]
      
      conditions = [
        options.delete(:conditions),
        start_at,
        end_at
      ].compact
      
      conditions = conditions.any? ? conditions.join(' AND ') : nil
      
      joins = ["INNER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
      joins << options.delete(:joins) if options[:joins]
      
      at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
      at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
      having    = [at_least, at_most].compact.join(' AND ')
      group_by  = "#{Tag.table_name}.id, #{Tag.table_name}.name, #{Tag.table_name}.permalink HAVING COUNT(*) > 0"
      group_by << " AND #{having}" unless having.blank?
      
      { :select     => "#{Tag.table_name}.id, #{Tag.table_name}.name, #{Tag.table_name}.permalink, COUNT(*) AS count", 
        :joins      => joins.join(" "),
        :conditions => conditions,
        :group      => group_by
      }.update(options)
    end
  end

  def score_name
    valid_name = false
    words = self.name.split(/\s/).reject{|w| w.blank?}
    score = words.size
    if score == 2
      score += Names::First.include?(words.first) ? 1 : 0
      score += Names::Last.include?(words.last) ? 1 : 0
      if score == 4
        valid_name = true # perfect score
      else
        score -= 2 # lose the extra points for being 2 words
        # wait and see based on how it compares to other scores
        #score = 0
      end
    else
      score = 0
      words.each do|word|
        score += Names::First.include?(word) ? 1 : 0
        score += Names::Last.include?(word) ? 1 : 0
      end
    end

    if( score > 2 )
      valid_name = true # perfect score
    elsif score == 2 and words.size == 1
      if words.first.downcase == 'madonna'
        valid_name = true # perfect score
      end
    end

    [score,valid_name]
  end

  def name?
    score_name.last
  end
end

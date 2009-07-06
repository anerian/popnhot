class Post < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  belongs_to :feed

  has_permalink :title

  #validates_uniqueness_of   :body
  validates_uniqueness_of   :permalink
  validates_presence_of     :title, :body, :published_at

  acts_as_taggable
  set_cached_tag_list_column_name "cached_tag_list"

  # list of tags to exclude
  def self.excluded_tags
    ["TMZ.com","PEOPLE","says","members","protectors","Read"]
  end

  def validate
    post = Post.find_by_title(self.title)
    return if post.nil?
    # check the published_at date
    if self.published_at == post.published_at and post.id != self.id
      errors.add(:title,"Duplicate entry(#{post.id}): #{post.title}")
    end
  end

  def published
    timeago(self.created_at)
  end

  def display_title(limit = 50)
    text = title.size > limit ? title[0..limit] + "..." : title
    text_encoding(text)
  end

  def text_encoding( text )
    ic = Iconv.new('ISO-8859-1//IGNORE','UTF-8')
    text.split(' ').collect{|p| ic.iconv(p +' ')[0..-2] }.join(' ')
  end

  def display_body(limit = 64)
    text = case feed.klass
      when /Tmz/
        plain_text
      when /UsMag/
        plain_text
      when /Celebuzz/
        plain_text
      when /People/
        plain_text
      when /PopSugar/
        plain_text
    else
      summary
    end

    if limit.nil?
      result = plain_text.split(/\s/)[0..128].join(' ').gsub(/&nbsp;/,' ').gsub(/&amp;/,' and ').gsub(/(\. )+/,' ') #gsub(/<\/?[^>]*>/, '. ').
    else
      result = text.split(/\s/)[0..limit].join(' ').gsub(/&nbsp;/,' ').gsub(/&amp;/,' and ').gsub(/(\. )+/,' ') #.gsub(/<\/?[^>]*>/, '. ')
    end
    Hpricot("<html><body>#{result}</body></html>",:fixup_tags => true).at('body').inner_html
  end

  def plain_text
    Hpricot("<html><body>#{self.body}</body></html>").at('body').inner_text #.gsub(/<\/?[^>]*>/, '. ').gsub(/&nbsp;/,' ').gsub(/&amp;/,' and ').gsub(/(\. )+/,' ')
  end

  def suggest(all_tags)
    tagger = Word::Tagger.new all_tags.collect{|tag| tag.name }, :words => 4
    result_tags = tagger.execute( plain_text )
    return result_tags.map{ |tag| all_tags.find{|l| l.name == tag} }
  end

  def retag(tagger, all_tags)
    tags = tagger.suggest( plain_text, 5 ).map{|t| t.first}.reject{|tag| Post.excluded_tags.include?(tag)}
    if tags.size < 5
      more_tags = suggest(all_tags).reject{|t| Post.excluded_tags.include?(t.name) }
      tags << more_tags.shift.name while( tags.size < 5 and !more_tags.empty? )
    end
    self.tag_list = tags.map{|t| t.gsub(/^[^\w]*/,'').gsub(/[^\w]*$/,'') }.reject{|t| Post.excluded_tags.include?(t)}
  end

  # given the body, create a summary
  def summarize!
    self.summary = plain_text.gsub(/Filed under:.*TMZ.com.\s:/,'').gsub(/Read more/,'').gsub(/\.\s*\./,' ').gsub(/\s\./,' ').gsub(/^\./,'')[0..400]
  end
        
  # Calculate the tag counts for all tags.
  # 
  # See Tag.counts for available options.
  def tag_counts(options = {})
    Tag.find(:all, find_options_for_tag_counts(options))
  end

  # options
  # :start_date, sets the time to measure against, defaults to now
  # :date_format, used with <tt>to_formatted_s<tt>, default to :default
  def timeago(time, options = {})
    start_date = options.delete(:start_date) || Time.new
    date_format = options.delete(:date_format) || :default
    delta_minutes = (start_date.to_i - time.to_i).floor / 60
    if delta_minutes.abs <= (8724*60) # eight weeks… I’m lazy to count days for longer than that
      distance = distance_of_time_in_words(delta_minutes);
      if delta_minutes < 0
        distance
      else
        "#{distance} ago"
      end
    else
      return "on #{system_date.to_formatted_s(date_format)}"
    end
  end

  def self.search(query, page = 1, options = {})
    page = page.to_i > 0 ? page.to_i : 1

    client = Riddle::Client.new  $sphinx_config['host'], $sphinx_config['port']
    client.limit = options[:per_page] || self.per_page
    client.offset = self.per_page * (page-1)
    client.match_mode = :any
    if options.key?(:sort_mode)
      client.sort_mode  = :extended
      client.sort_by = options[:sort_mode]
    end

    begin
      result = client.query(query, 'posts, posts_delta')
    rescue => e
      puts e.message, e.backtrace
      result = {:matches => []}
    end

    matches = result[:matches].inject({}){|hash, m| hash[m.delete(:doc)] = m; hash}

    begin
      records = find(matches.keys)
    rescue => e
      puts e.message, e.backtrace
      records = []
    end

    records = records.sort_by{|r| -matches[r.id][:weight] }
    %w[total total_found time].map(&:to_sym).each do |method|
      class << records; self end.send(:define_method, method) {result[method]}
    end

    records = WillPaginate::Collection.create(page, self.per_page, records.total) do |pager|
      pager.replace records
    end
  end

private
  def distance_of_time_in_words(minutes)
    case
      when minutes < 1
        "hot!"
      when minutes < 50
        #pluralize(minutes, "minute")
        if minutes == 1
          "#{minutes} minute"
        else
          "#{minutes} minutes"
        end
      when minutes < 90
        "one hour"
      when minutes < 1080
        "#{(minutes / 60).round} hours"
      when minutes < 1440
        "one day"
      when minutes < 2880
        "one day"
      else
        "#{(minutes / 1440).round} days"
    end
  end
end

#!/usr/bin/env ruby

require 'uri'
require 'rubygems'
require 'xml/libxml'
require 'curb'

class CurbRequest
  def self.get(url,user_agent = "dude wheres my car?"  )
    c = Curl::Easy.new(url) do|curl|
      curl.headers["User-Agent"] = user_agent
      curl.follow_location = true
    end
    c.perform
    c.body_str
  end
end

# http://developer.amazonwebservices.com/connect/entry.jspa?externalID=636&ref=featured
module AmazonReferral
  SERVICE='http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService&ResponseGroup=Small,Medium,Images'
  KEY='01B24Z988S1Z13CY6QR2'
  ASSOC_TAG='reaadia-20'

  
  class Response
    include XML::SaxParser::Callbacks
    attr_reader :total_results, :total_pages, :items

    def initialize
      @char_buffer = ""
      @read_chars = false
      @items = []
    end

    def self.create( content )
      parser = XML::SaxParser.new
      parser.string = content
      response = AmazonReferral::Response.new
      parser.callbacks = response
      parser.parse
      response
    end
  
    def on_start_element( name, attrs )
      # convert the tag into an instance method
      method = "start_#{name.downcase}"
      self.send(method, attrs) if self.respond_to?(method)
    end

    def on_end_element( name )
      # convert the tag into an instance method
      method = "end_#{name.downcase}"
      self.send(method) if self.respond_to?(method)
    end

    def on_characters( chars )
      @char_buffer << chars if @read_chars
    end

    def start_items( attrs )
      @items = []
    end

    def start_item( attrs )
      @cur_item = {}
    end

    def end_item
      @items << @cur_item
    end

    def start_totalresults( attrs )
      set_read_tag_body
    end

    def end_totalresults
      finish_tag_body
      @total_results = @char_buffer.to_i
    end
    
    def start_totalpages( attrs )
      set_read_tag_body
    end

    def end_totalpages
      finish_tag_body
      @total_pages = @char_buffer.to_i
    end

    def start_detailpageurl( attrs )
      set_read_tag_body
    end
    
    def end_detailpageurl
      finish_tag_body
      @cur_item[:detail_url] = @char_buffer
    end

    def start_url(attrs)
      set_read_tag_body
    end
    
    def end_url
      finish_tag_body
      @url = @char_buffer
    end

    def start_height(attrs)
      set_read_tag_body
    end

    def end_height
      finish_tag_body
      @height = @char_buffer
    end
    
    def start_width(attrs)
      set_read_tag_body
    end

    def end_width
      finish_tag_body
      @width = @char_buffer
    end

    def start_asin(attrs)
      set_read_tag_body unless @cur_item.nil?
    end

    def end_asin
      unless @cur_item.nil?
        finish_tag_body
        @cur_item[:id] = @char_buffer
      end
    end

    def end_smallimage
      @cur_item[:small_image] = {:url => @url, :width => @width, :height => @height}
    end
    
    def end_mediumimage
      @cur_item[:medium_image] = {:url => @url, :width => @width, :height => @height}
    end
    
    def end_largeimage
      @cur_item[:large_image] = {:url => @url, :width => @width, :height => @height}
    end
    
    def end_swatchimage
      @cur_item[:swatch_image] = {:url => @url, :width => @width, :height => @height}
    end

    def start_list_price(attrs)
      @in_list_price = true
    end
    def end_list_price
      @in_list_price = false
    end

    def start_formatted_price(attrs)
      set_read_tag_body
    end

    def end_formatted_price
      finish_tag_body
      @cur_item[:price] = @char_buffer if @cur_item and @in_list_price
    end

    def start_author(attrs)
      set_read_tag_body
    end

    def end_author
      finish_tag_body
      @cur_item[:author] = @char_buffer if @cur_item
    end

    def start_binding(attrs)
      set_read_tag_body
    end
    
    def end_binding
      finish_tag_body
      @cur_item[:binding] = @char_buffer
    end
    
    def start_creator(attrs)
      set_read_tag_body
    end
    
    def end_creator
      finish_tag_body
      @cur_item[:creator] = @char_buffer
    end
    
    def start_label(attrs)
      set_read_tag_body
    end
    
    def end_label
      finish_tag_body
      @cur_item[:label] = @char_buffer
    end
    
    def start_amount(attrs)
      set_read_tag_body
    end

    def end_amount
      finish_tag_body
      @amount = @char_buffer
    end

    def start_currencycode(attrs)
      set_read_tag_body
    end

    def end_currencycode
      finish_tag_body
      @currency_code = @char_buffer
    end
    
    def start_formattedprice(attrs)
      set_read_tag_body
    end

    def end_formattedprice
      finish_tag_body
      @formatted_price = @char_buffer
    end

    def end_listprice
      finish_tag_body
      @cur_item[:listprice] = {:amount => @amount, :currency_code => @currency_code, :formatted_price => @formatted_price}
    end

    def start_productgroup( attrs )
      set_read_tag_body
    end

    def end_productgroup
      finish_tag_body
      @cur_item[:product_group] = @char_buffer
    end
    
    def start_title( attrs )
      set_read_tag_body
    end

    def end_title
      finish_tag_body
      @cur_item[:title] = @char_buffer
    end

    def set_read_tag_body
      @read_chars = true
      @char_buffer = ""
    end

    def finish_tag_body
      @read_chars = false
    end

  end

  class BaseRequest
    attr_accessor :key, :assoc_tag

    def initialize( operation, options = {} )
      @operation = operation
      @params = {}
      options.each do|k,v|
        @params[k.to_s.split('_').collect{|p| p.capitalize }.join('')] = v
      end
      @key = KEY
      @assoc_tag = ASSOC_TAG
      @@counter ||= 0
    end

    def run
      url = "#{SERVICE}&AWSAccessKeyId=#{@key}&Operation=#{@operation}&AssociateTag=#{@assoc_tag}"
      @params.each {|k,v| url << "&#{k}=#{v}" }
      timer = Time.now
      buffer = CurbRequest.get( URI.escape(url) )
      File.open("item#{@@counter}-cached.xml", "w") do|f|
        f << buffer
      end
      @@counter += 1
      response = Response.create( buffer )
      puts "requested #{url}, with params:\n#{@params.inspect} in #{Time.now - timer} with #{response.items.size} products"
      response
    end
  end

  class SearchRequest < BaseRequest
    def initialize(options = {})
      super("ItemSearch",options)
    end
  end

  class LookupRequest < BaseRequest
    def initialize(item_id,options={})
      super("ItemLookup",options.merge(:item_id => item_id) )
    end
  end

  class RelatedRequest < BaseRequest
    def initialize(item_id,options={})
      super("SimilarityLookup",options)
    end
  end

end

if $0 == __FILE__
  require 'yaml'

  keywords = ['Lil Wayne', 'Celebrity Justice', 'TMZ.com', 'Music']
  for keyword in keywords do
    timer = Time.now
    text = 'Lil Wayne Celebrity Justice TMZ.com Music'
    #results = AmazonReferral::SearchRequest.new( :search_index => 'Books', :text_stream => text ).run #:keywords => keyword, :item_page => 1 ).run
    results = AmazonReferral::SearchRequest.new( :search_index => 'Music', :keywords => keyword, :item_page => 1 ).run
    puts "time to request xml: #{Time.now - timer}"
    require 'pp'
    item = results.items.first
    next if item.nil?
    id = item[:id]
    puts "\n\n\n#{id.inspect}"

    results = AmazonReferral::LookupRequest.new( id, :id_type => 'ASIN' ).run
    pp results
  end
#  timer = Time.now
#  cache = File.read("cached.xml")
#  response = AmazonReferral::Response.create( cache )
#  require 'pp'
#  response.items.each do|item|
#    pp item
#    puts "\n\n\n"
#  end
#  puts "time to parse xml: #{Time.now - timer}"
#  File.open("cached.yml","w") do|f|
#    f << YAML.dump({:total_results => response.total_results,
#          :total_pages => response.total_pages,
#          :items => response.items})
#  end
#  timer = Time.now
#  r = YAML.load_file("cached.yml")
#  puts "time to load cached yaml #{Time.now - timer}"
end

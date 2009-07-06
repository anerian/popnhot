require 'rubygems'
require 'xml/libxml'

module StreamXML
  class ParseReader
    include XML::SaxParser::Callbacks

    def initialize
      @grab_for = []
      @captures = {}
      @in_unwatched = 0
      @depth = 0
    end

    def self.execute_buffer(buffer)
      context = StreamXML::ParseReader.new
 
      # based on the extraction block 
      # define callbacks to catch specific content
      yield context 

      parser = XML::SaxParser.string(buffer)
      parser.callbacks = context
      r = parser.parse
      context
    end

    def self.execute_file(file)
      parser = XML::SaxParser.file(file)
      #parser.filename = file
      context = StreamXML::ParseReader.new

      # based on the extraction block 
      # define callbacks to catch specific content
      yield context 

      parser.callbacks = context
      parser.parse
      context
    end

    def collection(name,xpath,options={})
      @assign_collection = true
      @collection_name = "@#{rb_name(name)}"
      @capture_node = xpath.split('/').reject{|i| i.nil? }.last
      @captures[@capture_node] = {:names => [],:action => lambda{} }
      instance_variable_set(@collection_name,[])
      self.class.send(:attr_reader,name.to_sym)
      @collection_node_name = xpath.split('/').last
      watch_element(@collection_node_name)
      yield self
      @assign_collection = false
      @collection_node_name = nil
      self
    end
 
    def capture
      @captures[@capture_node][:action] = lambda {|item| yield item  } 
    end

    def content_for(xpath,options={},&action)
      watching = watch_path(xpath)
      var_name = "@__#{rb_name(options[:as] || watching.last)}"
      replace_var = "@__#{rb_name(options[:as] || watching.last)}_replace"
      if options[:replace]
        self.instance_variable_set(replace_var,true)
      else
        self.instance_variable_set(replace_var,false)
      end
      # mark as a collection
      self.instance_variable_set(var_name,[]) if options[:collect]
      self.instance_variable_set(var_name,options[:capture] ? [] : '') unless instance_variable_defined?(var_name)
      watch_content_in_chain(watching,var_name,action)
    end

    def attr_for(xpath,options={},&action)
      watching = watch_path(xpath)
      raise "capture required with attr_for" unless options.keys.include?(:capture)
      var_name = "@__#{rb_name(options[:as] || options[:capture])}"
      replace_var = "@__#{rb_name(options[:as] || watching.last)}_replace"
      if options[:replace]
        self.instance_variable_set(replace_var,true)
      else
        self.instance_variable_set(replace_var,false)
      end
      @captures[@capture_node][:names] << var_name if @assign_collection
      self.instance_variable_set(var_name,options[:capture] ? [] : '') unless instance_variable_defined?(var_name)
      watch_content_in_chain(watching,var_name,action,options)
    end

  #private

    def watch_path(xpath)
      watching = xpath.split('/')
      watching.select do|el|
        next nil if el == ""
        watch_element( el )
        el
      end
    end

    # convert the given name str into a safe ruby variable name
    def rb_name(name)
      name.to_s.gsub(/[^\w]/,'_')
    end

    def watch_element(element_name)
      return if self.respond_to?("start_watch_#{rb_name(element_name)}") # ensure we only watch this element once
      watch_methods = %Q{
        def start_watch_#{rb_name(element_name)}(attrs)
          @in_#{rb_name(element_name)} = true
          start_grab_element_for("#{element_name}",attrs)
        end

        def end_watch_#{rb_name(element_name)}()
          @in_#{rb_name(element_name)} = false
          end_grab_element_for("#{element_name}")
          end_collection_element_for("#{element_name}")
        end
      }
      self.instance_eval( watch_methods )
      self.instance_variable_set("@in_#{rb_name(element_name)}",false)
    end

    def match_chain_for(name)
      chains = @grab_for.select{|gf| gf[:chain].last == name and gf[:chain].size == @depth }
      if !chains.empty?
        # all possible chains for this element
        chains.each do|chain|
          # node path that must all be a match
          matched = true
          for node_name in chain[:chain] do
            matched |= self.instance_variable_get("@in_#{rb_name(node_name)}")
          end
          if matched and @in_unwatched == 0
            yield chain
            break
          end
        end
      end
    end

    def start_grab_element_for(name,attrs)
      match_chain_for(name) do|chain|
        @collection_name = chain[:collection] if chain[:collection]
        if @collection_node_name.nil? and chain[:collection]
          @collection_node_name = chain[:collection_node]
          #puts "create the collection hash named: @#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}"
          # creates the collection item hash
          self.instance_variable_set("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}", {})
        end
        if chain[:watch_attr].nil?
          set_read_tag_body
        else
          watch_attr = chain[:watch_attr]
          value = attrs[watch_attr[:capture].to_s]
          if watch_attr[:match]
            # check for a match of any of the keys
            watch_attr[:match].each do|key,expr|
              val = attrs[key.to_s]
              if val and val.match(expr)
                @char_buffer = value
                break
              end
            end
          else
            @char_buffer = value
          end
        end
      end
    end

    def end_grab_element_for(name)
      match_chain_for(name) do|chain|
        if chain[:collection]
          @collection_name = chain[:collection]
          @collection_node_name = chain[:collection_node]
          #puts "set: #{@collection_name}, #{@collection_node_name}, given: #{name}"
          var_name = chain[:var_name]
          if self.instance_variable_get(var_name).is_a?(Array)
            self.instance_variable_get("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}")[var_name.gsub(/@__/,'').to_sym] ||= []
          else
            #puts "@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}"
            self.instance_variable_get("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}")[var_name.gsub(/@__/,'').to_sym] ||= ""
          end
          if self.instance_variable_get("#{var_name}_replace") == true
            self.instance_variable_get("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}")[var_name.gsub(/@__/,'').to_sym] = @char_buffer
          else
            self.instance_variable_get("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}")[var_name.gsub(/@__/,'').to_sym] << @char_buffer
          end
        else
          chain[:action].call @char_buffer
        end
        finish_tag_body
      end
    end

    def end_collection_element_for(name)
      if @captures[name]
        @captures[name][:action].call self.instance_variable_get("@#{rb_name(@collection_name)}_#{rb_name(@collection_node_name)}")
        @collection_node_name = nil
        @collection_name = nil
      end
    end

    def watch_content_in_chain(chain,var_name,action,watch_attr=nil)
      if @assign_collection
        @grab_for << {:var_name => var_name,
                      :chain => chain,
                      :collection => @collection_name,
                      :collection_node => @collection_node_name, 
                      :action => action,
                      :watch_attr => watch_attr}
      else
        @grab_for << {:chain => chain, :action => action, :watch_attr => watch_attr}
      end
    end

    def on_start_element( name, attrs )
      #puts "element start: #{name} #{attrs.inspect}"
      # watch this element
      @depth += 1
      watch_method = "start_watch_#{rb_name(name)}"
      if self.respond_to?(watch_method)
        self.send(watch_method, attrs)
      else
        @in_unwatched += 1
      end
    end

    def on_end_element( name )
      watch_method = "end_watch_#{rb_name(name)}"
      if self.respond_to?(watch_method)
        self.send(watch_method)
      else
        @in_unwatched -= 1
      end
      @depth -= 1
    end

    def on_characters( chars )
      @char_buffer << chars if @read_chars
    end

    def on_cdata_block( chars )
      @char_buffer << chars if @read_chars
    end

    def set_read_tag_body
      @read_chars = true
      @char_buffer = ""
    end

    def finish_tag_body
      @read_chars = false
    end

  end
end

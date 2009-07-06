module Merb
  def self.load_external_environment(app_path)
    gem = Dir.glob(app_path + "/gems/gems/merb-core-*").last
    raise "Can't run frozen without framework/ or local gem" unless gem

    if File.directory?(gem)
      $:.push File.join(gem,"lib")
    end

    require gem + "/lib/merb-core/core_ext/kernel"
    require gem + "/lib/merb-core/core_ext/rubygems"

    Gem.clear_paths
    Gem.path.unshift(app_path+"/gems")
    require 'merb-core'

    Merb.frozen!
    Merb::Config.setup
    Merb::Config[:merb_root] = app_path
    Merb::Config[:environment] = "development"
    Merb.environment = Merb::Config[:environment]
    Merb.root = Merb::Config[:merb_root]
    puts Merb::Config.to_yaml

    require app_path + '/config/init'

    puts Gem.path.inspect

    Merb.load_config
    Merb.load_dependencies
    Merb::BootLoader.run
  end

  def self.startup
    # Require with patched rubygems
    require File.dirname(__FILE__) + "/../gems/gems/merb-core-0.9.3/lib/merb-core/core_ext/rubygems"

    $project_root = File.expand_path(File.join(File.dirname(__FILE__),'..'))
    Gem.clear_paths
    Gem.path.unshift(File.join($project_root, "gems"))

    #puts " ~ Using gem paths: #{Gem.path.join(", ")}"

    Merb.load_external_environment($project_root)
    #Merb.push_path(:lib, Merb.root / "lib") # uses **/*.rb as path glob.
    $:.unshift(File.join(File.dirname(__FILE__),'lib'))
  end
end

Merb.startup

require 'rbtagger'
require 'news/feed'

class FeedLoader
  attr_reader :tagger

  def initialize
    puts "loading tagger..."
    timer = Time.now
    @tagger = tagger = Brill::Tagger.new( File.join($project_root,'config','LEXICON'),
                                          File.join($project_root,'config','LEXICALRULEFILE'),
                                          File.join($project_root,'config','CONTEXTUALRULEFILE') )
    puts "tagger loaded in #{Time.now - timer}"
  end

  def refresh(feed_url,all_tags,type='application/rss+xml',klass = News::Feed)
    arfeed = Feed.find_by_url(feed_url)
    if arfeed.nil?
      puts "creating feed #{feed_url}..."
      arfeed = Feed.setup(feed_url,type,klass)
      arfeed.save!
    end
    arfeed.refresh_posts( @tagger, all_tags )
  end

end
puts ARGV.inspect

if ARGV[0] == 'summarize'
  puts "resummarize posts"
  Feed.find(:all,:include => :posts).each do|feed|
    feed.posts.each do|post|
      post.summarize!
      post.save!
    end
  end

elsif ARGV[0] == 'tags'
  Tag.find(:all).each do|tag|
    tag.name = tag.name
    puts tag.permalink
    tag.save!
  end

elsif ARGV[0] == 'images'
  require 'digest/md5'
  require 'fileutils'
  require 'rmagick'

  puts "normalize images"
  FileUtils.mkdir_p(File.join($project_root,'public','files')) # ensure this is created
  # use curb to fetch the image
  # use rmagick to scale the image to our thumb size either width 120 or height 120 depending on which is more fitting
  Feed.find(:all,:include => :posts).each do|feed|
    feed.posts.each do|post|
      #next if post.image.blank?
      doc = Hpricot("<html><body>#{post.image}</body></html>")
      (doc/"img").each do|image|
        digest = Digest::MD5.new
        src = image['src']
        next unless src.match(/http:/)
        puts "processing #{File.basename(src)}..."
        ext = File.extname(image['src']).sub(/\./,'')
        digest.update(src)
        digest = digest.hexdigest
        http_path = "/files/#{ext}/#{digest[0..2]}/"
        dest_dir = File.join($project_root,'public',http_path)
        FileUtils.mkdir_p(dest_dir)
        dest_file = "#{dest_dir}/#{digest}.png"
        blob = curb_get(src)
        puts "loading image #{src}: #{blob.size}"
        rimg = Magick::Image.from_blob( blob ).first
        puts "image loaded from blob"
        rimg.change_geometry!("120x120") do|cols,rows,img|
          puts "resize: #{cols} #{rows}"
          img.resize!(cols,rows)
        end
        puts "writing file: #{dest_file}"
        rimg.write dest_file
        http_path += digest + '.png'
        n_image = %Q(<img class="image_thumb" src="#{http_path}"/>)
        image.swap(n_image)
      end
      post.image = doc.at("body").inner_html
      post.save!
    end
  end
elsif ARGV[0] == 'retag'
  floader = FeedLoader.new
  all_tags = Tag.find(:all)
  Tag.destroy_unused = true
  all_tags.each do|tag|
    if Post.excluded_tags.include?(tag)
      Tag.find_by_name(tag).destroy
    end
  end

  # retag content for feed
  Feed.find(:all,:include => :posts).each do|feed|
    puts feed.title
    feed.posts.each do|post|
      post.retag(floader.tagger,all_tags)
      post.save!
      puts post.tag_list.inspect
    end
  end
elsif ARGV[0] == 'revalidate'

  Post.find(:all).each do|post|
    if !post.valid?
      post.destroy
    end
  end

elsif ARGV[0] == 'refresh'
  floader = FeedLoader.new
  all_tags = Tag.find(:all)

  # ensure these feeds exist
  floader.refresh('http://feeds.usmagazine.com/celebrity_news/atom', all_tags, 'application/atom+xml',News::UsMag)
  floader.refresh('http://tmz.com/rss.xml', all_tags, 'application/rss+xml', News::Tmz)
  floader.refresh('http://rss.people.com/web/people/rss/topheadlines/index.xml', all_tags, 'application/rss+xml', News::People)
else
  system("ruby rbfeed.rb refresh")
  system("ruby rbfeed.rb images") 
  system("ruby rbfeed.rb retag")
  system("rake sphinx:rotate")
end

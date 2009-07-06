module Merb
  def self.load_external_environment(app_path)
    gem = Dir.glob(app_path + "/gems/gems/merb-core-*").last
    raise "Can't run frozen without framework/ or local gem" unless gem

    if File.directory?(gem)
      $:.push File.join(gem,"lib")
    end

    require gem + "/lib/merb-core/core_ext/kernel"
    #require gem + "/lib/merb-core/core_ext/rubygems"

    Gem.clear_paths
    puts Gem.path.inspect

    Gem.path.unshift(app_path+"/gems")
    require 'merb-core'

    Merb.frozen!
    Merb::Config.setup
    Merb::Config[:merb_root] = app_path
    Merb::Config[:environment] = ENV["MERB_ENV"] || "development"
    Merb.environment = Merb::Config[:environment]
    Merb.root = Merb::Config[:merb_root]
    puts Merb::Config.to_yaml

    require app_path + '/config/init'

    puts Gem.path.inspect

    Merb.load_config
    Merb.load_dependencies
    Merb::BootLoader.run
  end

  def self.load_externally(merb_projpath)
    # Require with patched rubygems
    #require "#{merb_projpath}/gems/gems/merb-core-0.9.3/lib/merb-core/core_ext/rubygems"

    Gem.clear_paths
    Gem.path.shift until Gem.path.empty? # work around clear_paths doesn't really clear'em
    puts Gem.path.inspect
    Gem.path.unshift(File.join(merb_projpath, "gems"))
    puts Gem.path.inspect

    Merb.load_external_environment(merb_projpath)

    $:.unshift(File.join(File.dirname(__FILE__),'lib'))
  end
end

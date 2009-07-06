# Copyright (c) 2008 Todd A. Fisher
#
require 'rubygems'
require 'spec'
require 'mocha'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

TESTING=true
SPEC_DIR=File.dirname(__FILE__)
LOG_DIR=File.expand_path(File.join(SPEC_DIR,'..','log') )

require 'stream_xml/parse_reader'
require 'news_feed'
require 'crawl'

MOCK_DIR=SPEC_DIR + '/mocks'
DIR_ROOT=File.expand_path(File.join(File.dirname(__FILE__),'..','..') )
Spec::Runner.configure do |config|
  def fixture(name)
    File.read(fixture_path(name))
  end

  def fixture_path(name)
    File.join(MOCK_DIR,name)
  end
end

require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path( link.gsub(/^http:\/\//,'').gsub(/\?.*$/,'') )))}"
  end
end

describe 'Extracting PopSugar Content' do
  
  before(:all) do
    feed = OpenStruct.new({:klass => 'PopSugar',
                           :content_type => 'application+rss/xml',
                           :url => "http://feeds.feedburner.com/popsugar" })
 
    @posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,fobj|
        @posts << post
      end.run
    end
  end

  it 'should find feeds' do
    @posts.size.should == 5
  end

  it 'should find a thumbnail or image' do
    for post in @posts do
      post[:thumb_path].should_not == nil
    end
  end

  it 'should remove feedburner tracking image from description text' do
    for post in @posts do
      post[:body].should_not =~ /<img/
    end
  end

end

require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path( link.gsub(/^http:\/\//,'').gsub(/\?.*$/,'') )))}"
  end
end

describe 'Extracting Us Magazine Content' do
  
  before(:all) do
    feed = OpenStruct.new({:klass => 'UsMag',
                           :content_type => 'application/atom+xml',
                           :url => "http://feeds.usmagazine.com/celebrity_news/atom" })
    @posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,fobj|
        @posts << post
      end.run
    end
  end

  it 'should convert ip hostnames to usmagazine.com hostnames' do
    for post in @posts do
      post[:link].should =~ /usmagazine.com/
    end
  end

  it 'should find images for usmagazine.com content' do
    for post in @posts do
      post[:thumb_path].should_not == nil
      File.exist?(post[:thumb_path]).should == true
    end
  end

  it 'should extract the body content for usmagazine.com' do
    for post in @posts do
      post[:body].should_not == nil
    end
  end
  
  it 'should extract a summary for usmagazine.com' do
    for post in @posts do
      post[:summary].should_not == nil
      post[:summary].should_not =~ /\&lt;|\&gt;/
    end
  end

  it 'should detect video posts' do
    session = {}
    crawl = Crawl::UsMag.new(DIR_ROOT,@session,{},'',NewsFeed::Atom)
    extracted = crawl.extract(fixture('www.usmagazine.com/elisabeth-hasselbeck-breaks-down-in-tears-over-n-word'),
                              URI.parse('http://www.usmagazine.com/elisabeth-hasselbeck-breaks-down-in-tears-over-n-word') )
    extracted.should_not == nil
    body = extracted[:body]
    body.should_not == nil
    extracted[:video].should == true
  end

end

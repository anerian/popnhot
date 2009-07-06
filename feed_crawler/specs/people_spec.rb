require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path( link.gsub(/^http:\/\//,'').gsub(/\?.*$/,'') )))}"
  end
end

describe 'Extracting People Content' do
  
  before(:all) do
    feed = OpenStruct.new({:klass => 'People',
                           :content_type => 'application+rss/xml',
                           :url => "http://rss.people.com/web/people/rss/topheadlines/index.xml" })
    
    @posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,fobj|
        @posts << post
      end.run
    end
  end

  it 'should expand keywords from original rss content' do
    for post in @posts do
      if post[:category]
        post[:category].each do|keyword|
          keyword.should_not =~ /,/
        end
      end
    end
  end

  it 'should find a thumbnail or image' do
    for post in @posts do
      post[:thumb_path].should_not == nil
    end
  end

  it 'should remove feedburner tracking image from description text' do
    for post in @posts do
      post[:summary].should_not =~ /<img/
    end
  end

  it 'should replace empty author fields with People' do
    for post in @posts do
      post[:author].should == 'People'
    end
  end
end

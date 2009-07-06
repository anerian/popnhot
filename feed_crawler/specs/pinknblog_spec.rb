require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path( link.gsub(/^http:\/\//,'').gsub(/\?.*$/,'') )))}"
  end
end

describe 'Extracting Pink is the new blog Content' do
  before(:all) do
    feed = OpenStruct.new({:klass => 'PinknBlog',
                           :content_type => 'application+rss/xml',
                           :url => "http://pinkisthenewblog.com/home/feed" })
    
    @posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,fobj|
        @posts << post
      end.run
    end
  end

  it 'should find 10 posts' do
    @posts.size.should == 10
  end

  it 'should find a thumb for each post' do
    images = 0
    @posts.each do|p|
      p[:title].should_not == nil
      p[:link].should_not == nil
      images += 1 if p[:thumb_path]
    end
    images.should == 8
  end
  
  it 'should find a video' do
    p = @posts.select{|p| p[:link] == 'http://pinkisthenewblog.com/home/harry-potter-and-the-half-blood-prince-gets-a-trailer/' }.first
    p[:thumb_path].should == nil
  end

  it 'should strip html from description text' do
    @posts.each do|p|
      p[:description].should_not =~ /<img|<object/
    end
  end
end

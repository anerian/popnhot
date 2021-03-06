require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path( link.gsub(/^http:\/\//,'').gsub(/\?.*$/,'') )))}"
  end
end

describe 'Extracting Eonline Content' do
  
  before(:all) do
    feed = OpenStruct.new({:klass => 'Eonline',
                           :content_type => 'application+rss/xml',
                           :url => "http://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml" })
    
    @posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,fobj|
        @posts << post
      end.run
    end
  end

  it "should extract posts" do
    @posts.size.should == 10
  end

  it "should have an author field" do
    @posts.each do|p|
      p[:author].should_not == nil
    end
  end

  it "should not have images or other markup in the summary" do
    @posts.each do|p|
      p[:summary].should_not =~ /<img|<script|<br/
    end
  end

  it "should have links for each content item" do
    @posts.each do|p|
      p[:link].should_not == nil
    end
  end

  it "should find thumbs for content or it should be a video" do
    @posts.each do|p|
      #puts "#{p[:link]} => #{p[:thumb_path].inspect}"
      if p[:thumb_path]
        p[:thumb_path].should_not == nil
      else
        p[:image].should_not == nil
      end
    end
  end

  it "should detect youtube videos" do
    @session = {}
    @crawl = Crawl::Eonline.new(DIR_ROOT,@session,{},'',NewsFeed::RSS)
    extracted = @crawl.extract(fixture('www.eonline.com/uberblog/b147980_comic-con_lost_video_producers_talk.html'),
                               URI.parse('http://www.eonline.com/uberblog/b147980_comic-con_lost_video_producers_talk.html'),{})
    extracted[:video].should == true
  end

  it "should find the entry_content body" do
    @posts.each do|p|
      p[:body].should_not == nil
    end
  end

end

require File.dirname(__FILE__) + '/helper.rb'

describe 'feed reading' do
  
  it "should include media and feedburner origLink" do
    url = "http://rss.people.com/web/people/rss/topheadlines/index.xml"
    fa = NewsFeed::RSS.new
    # mock out request
    fa.expects(:request).with(url).returns(File.read(fixture_path('rss.people.com/web/people/rss/topheadlines/index.xml')))
    title = ""
    link = ""
    items = []

    fa.read(url) do |cfg|
      cfg.title {|title| title = title }
      cfg.link {|link| link = link }
      cfg.item {|item| items << item }
    end
    solution = {:published_at=>"Thu, 17 Jul 2008 10:00:00 EDT",
                :title=>"Keith Urban Calls Parenthood 'Pure Bliss'",
                :link=>"http://www.people.com/people/article/0,,20213331,00.html?xid=rss-topheadlines",
                :thumbnail=>["http://img2.timeinc.net/people/i/2008/news/080714/kidman_urban75.jpg"],
                :category=>["Babies, Keith Urban, Nicole Kidman"],
                :image=>["http://img2.timeinc.net/people/i/2008/news/080714/kidman_urban150.jpg"],
                :description=>"\"We're all doing superbly well,\" says the singer of life with his 10-day-old daughter with Nicole Kidman<img src=\"http://feeds.feedburner.com/~r/people/headlines/~4/338597083\" height=\"1\" width=\"1\"/>"}

    items.first[:published_at].should == solution[:published_at]
    items.first[:title].should == solution[:title]
    items.first[:link].should == solution[:link]
    items.first[:thumbnail].should == solution[:thumbnail]
    items.first[:category].should == solution[:category]
    items.first[:image].should == solution[:image]
    items.first[:description].should == solution[:description]
  end

  it "should extract items for rss" do
    url = 'http://www.tmz.com/rss.xml'

    fa = NewsFeed::RSS.new

    # mock out request
    fa.expects(:request).with(url).returns(File.read(fixture_path('rss.xml')))
 
    link = ""
    title = ""
    items = []

    fa.read( url ) do|cfg|
      cfg.title {|title| title = title }
      cfg.link {|link| link = link }
      cfg.item {|item| items << item }
    end
    
    title.should == 'TMZ.com'
    link.should == 'http://www.tmz.com'

    items.size.should == 20
    items.first[:title].should == "Fiddy's Ex Got Served!"
    items.first[:link].should == "http://www.tmz.com/2008/06/20/fiddy-to-ex-sh-sh-sh-shut-your-trap/"
    items.first[:published_at].should == "2008-06-20T14:11:00+00:00"
    items.first[:author].should == "TMZ Staff"
    items.first[:category].should == nil

    items[2][:description].should == %{<p>Filed under: <a href="http://www.tmz.com/category/paparazzi-photo/" rel="tag">Paparazzi Photo</a>, <a href="http://www.tmz.com/category/wacky-and-weird/" rel="tag">Wacky &amp; Weird</a>, <a href="http://www.tmz.com/category/fashion-police/" rel="tag">Fashion Police</a>, <a href="http://www.tmz.com/category/fashion/" rel="tag">Full Throttle Fashion</a></p><a href="http://www.tmz.com">TMZ.com</a>:  Even in her down time, unwed A-list bag lady Helena Bonham Carter dresses like she's in one of her boyfriend Tim Burton's films. Corpse Bride!With her static cling pullover, belted duvet cover and atrociously sensible, orthopedic lace-ups, HBC really... <a href="http://www.tmz.com/2008/06/20/helena-bonham-carter-looks-like-sheet/">Read more</a><br/><br/>}
    items[2][:title].should == "Helena Bonham Carter Looks Like Sheet"
    items[2][:link].should == "http://www.tmz.com/2008/06/20/helena-bonham-carter-looks-like-sheet/"
    items[2][:published_at].should == "2008-06-20T13:15:00+00:00"
    items[2][:category].should == ["Helena Bonham Carter", "HelenaBonhamCarter"]

    items.last[:title].should == "Careful Daddy, That's a Live One!"
    items.last[:link].should == "http://www.tmz.com/2008/06/19/careful-daddy-thats-a-live-one/"
    items.last[:published_at].should == "2008-06-19T17:53:00+00:00"
    items.last[:author].should == "TMZ Staff"
    items.last[:category].should == ["Casey Aldridge", "CaseyAldridge", "Jamie Lynn Spears", "JamieLynnSpears"]
  end

  it "should extract entries for atom" do
    url = 'http://feeds.usmagazine.com/celebrity_news/atom'

    fa = NewsFeed::Atom.new

    # mock out request
    fa.expects(:request).with(url).returns(File.read(fixture_path('atom.xml')))
 
    link = ""
    title = ""
    items = []

    fa.read( url ) do|cfg|
      cfg.title {|title| title = title }
      cfg.link {|link| link = link }
      cfg.item {|item| items << item }
    end
 
    title.should == "Usmagazine.com celebrity_news"
    link.should == "http://64.90.166.18/celebrity_news"
    items.size.should == 10
    
    items.first[:title].should == "Actor Matthew Broderick: Our Son Is \"Curious\" About Smoking"
    items.first[:link].should == "http://64.90.166.18/matthew-broderick-our-son-is-curious-about-smoking"
    items.first[:published_at].should == "2008-06-20T13:13:51-04:00"
    items.first[:author].should == "Mandi Illuzzi"
    items.first[:category].should == ["Matthew Broderick", "Sarah Jessica Parker", "smoking"]

    items[2][:description].should == %{<p>She and &lt;b&gt;Brad Pitt&lt;/b&gt; have &quot;made a point to ... not be working,&quot; she says</p>\n    }
    items[2][:title].should == "Angelina Jolie Staying \"Home With the Kids\" Until Twins Are Born"
    items[2][:author].should == "Alissa R"
    items[2][:link].should == "http://64.90.166.18/angelina-jolie-before-twins-birth-well-be-home-together-with-the-kids"
    items[2][:published_at].should == "2008-06-20T11:24:55-04:00"
    items[2][:category].should == ["Angelina Jolie", "Brad Pitt", "Maddox Jolie-Pitt", "Pax", "Shiloh Jolie-Pitt", "Zahara Jolie-Pitt", "Babies", "Brangelina"]

    items.last[:title].should == "Britney Spears' Mom Tells Court: She \"Intends to Return to Louisiana\""
    items.last[:link].should == "http://64.90.166.18/britney-spears-mom-she-intends-to-return-to-louisiana"
    items.last[:published_at].should == "2008-06-19T15:06:53-04:00"
    items.last[:author].should == "Henry Seltzer"
    items.last[:category].should == ["Britney Spears", "Jamie Lynn Spears", "Jamie Spears", "Kevin Federline", "Lynne Spears"]

  end
end

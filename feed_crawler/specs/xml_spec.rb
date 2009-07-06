require File.dirname(__FILE__) + '/helper.rb'

describe 'xml parser' do
  
  it "should parse rss xml" do
    channel = {}
    items = []

    StreamXML::ParseReader.execute_file(fixture_path('rss.xml')) do|ctx|
      
      ctx.content_for('//rss/channel/title') {|title| channel[:title] = title }
      ctx.content_for('//rss/channel/link') {|link| channel[:link] = link }
      ctx.content_for('//rss/channel/description') {|desc| channel[:description] = desc }

      ctx.collection(:items,'//rss/channel/item') do|si|
        si.content_for('//rss/channel/item/title')
        si.content_for('//rss/channel/item/link')
        si.content_for('//rss/channel/item/description')
        si.content_for('//rss/channel/item/category', :collect => true)
        si.content_for('//rss/channel/item/dc:creator', :as => :author)
        si.content_for('//rss/channel/item/dc:date', :as => :published_at)
      end.capture do|item|
        items << item
      end
    end

    channel[:title].should == 'TMZ.com'
    channel[:link].should == 'http://www.tmz.com'
    channel[:description].should == 'TMZ.com'

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

    #items.map{|i| puts i[:category].inspect}
  end

  it "should parse atom" do
    channel = {}
    entries = []

    StreamXML::ParseReader.execute_file(fixture_path('atom.xml')) do|ctx|
      ctx.content_for('//feed/title'){|title| channel[:title] = title}
      ctx.attr_for('//feed/link',:capture => :href, :match => {:type => /text\/html/} ){|link| channel[:link] = link}
      ctx.collection(:entries,'//feed/entry') do|entry|
        entry.content_for('//feed/entry/title')
        entry.attr_for('//feed/entry/link',:capture => :href, :match => {:type => /text\/html/} )
        entry.content_for('//feed/entry/content')
        entry.content_for('//feed/entry/summary')
        entry.attr_for('//feed/entry/category', :capture => :term, :collect => true)
        entry.content_for('//feed/entry/author/name', :collect => true)
        entry.content_for('//feed/entry/published')
      end.capture do|entry|
        entries << entry
      end
    end

    channel[:title].should == "Usmagazine.com celebrity_news"
    channel[:link].should == "http://64.90.166.18/celebrity_news"
    entries.size.should == 10
 
    entries.first[:title].should == "Actor Matthew Broderick: Our Son Is \"Curious\" About Smoking"
    entries.first[:href].should == ["http://64.90.166.18/matthew-broderick-our-son-is-curious-about-smoking"]
    entries.first[:published].should == "2008-06-20T13:13:51-04:00"
    entries.first[:name].should == ["Mandi Illuzzi"]
    entries.first[:term].should == ["Matthew Broderick", "Sarah Jessica Parker", "smoking"]

    entries[2][:summary].should == %{<p>She and &lt;b&gt;Brad Pitt&lt;/b&gt; have &quot;made a point to ... not be working,&quot; she says</p>\n    }
    entries[2][:title].should == "Angelina Jolie Staying \"Home With the Kids\" Until Twins Are Born"
    entries[2][:name].should == ["Alissa R"]
    entries[2][:href].should == ["http://64.90.166.18/angelina-jolie-before-twins-birth-well-be-home-together-with-the-kids"]
    entries[2][:published].should == "2008-06-20T11:24:55-04:00"
    entries[2][:term].should == ["Angelina Jolie", "Brad Pitt", "Maddox Jolie-Pitt", "Pax", "Shiloh Jolie-Pitt", "Zahara Jolie-Pitt", "Babies", "Brangelina"]

    entries.last[:title].should == "Britney Spears' Mom Tells Court: She \"Intends to Return to Louisiana\""
    entries.last[:href].should == ["http://64.90.166.18/britney-spears-mom-she-intends-to-return-to-louisiana"]
    entries.last[:published].should == "2008-06-19T15:06:53-04:00"
    entries.last[:name].should == ["Henry Seltzer"]
    entries.last[:term].should == ["Britney Spears", "Jamie Lynn Spears", "Jamie Spears", "Kevin Federline", "Lynne Spears"]

  end

end

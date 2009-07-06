require File.dirname(__FILE__) + '/helper.rb'

class Crawl::Session
  def hook(link)
    # translate link to file path
    "file://#{URI.escape(File.expand_path(fixture_path(link.gsub(/^http:\/\//,''))))}"
  end
end

describe 'Running a session' do
  
  it 'should process multiple posts asynchronously' do
    stage_root = "#{DIR_ROOT}/staging/www.blogsmithmedia.com/www.tmz.com/media/2008/06"
    images = 
    ['0617_guys_launch.jpg','0619_jamie_casey_more_details.jpg',
     '0620_50_shaniqua_exl.jpg','0620_courtney_love_ramey.jpg',
     '0620_denise_launch.jpg','0620_faith_tim_splash_02.jpg',
     '0620_fifty_shaniqua.jpg','0620_helena_bonham_carter_ramey_01.jpg',
     '0620_kid_launch.jpg','0620_stewart_bn.jpg',
     'picture-184.png','picture-188.png']
    images.each do|img|
      FileUtils.rm_f("#{stage_root}/#{img}")
    end

    # mock tmz feed
    feed = OpenStruct.new({:klass => 'Tmz',
                           :content_type => 'application+rss/xml',
                           :url => "http://www.tmz.com/rss.xml" })
    posts = []
    Crawl::Session.run(DIR_ROOT) do|cfg|
      cfg.extractor(feed).posts do|post,feed_obj|
        posts << post
      end.run
    end

    posts.size.should == 20
    for post in posts do
      if post[:thumb_path]
        File.exist?(post[:thumb_path]).should == true
      end
    end

    first = {:published_at=>"2008-06-20T07:31:00+00:00",
             :body=>"Naomi Campbell just fessed up to going all, well, Naomi Campbell on a pair of police officers.The supermodel pleaded guilty to four charges in a west London court today, including two of assaulting the po-po and one \"public order offense.\" Her rep said that Campbell admitted in court that the incident was \"regrettable.\"Campbell freaked out in first class on a plane when she thought her baggage had been lost.A judge sentenced her to 200 hours of community service, in addition to a nearly $5000 fine, she was ordered to pay $400 to each of the officers she attacked and $300 to the pilot of plane.",
             :author=>"TMZ Staff",
             :image=>'/images/video.png',
             :link=>"http://www.tmz.com/2008/06/20/naomi-cops-to-clobbering-coppers/",
             :title=>"Naomi Cops to Clobbering Coppers",
             :tag_list=>["Naomi Campbell", "NaomiCampbell"],
             :summary=>"<p>Filed under: <a href=\"http://www.tmz.com/category/celebrity-justice/\" rel=\"tag\">Celebrity Justice</a></p><a href=\"http://www.tmz.com\">TMZ.com</a>:  Naomi Campbell just fessed up to going all, well, Naomi Campbell on a pair of police officers.The supermodel pleaded guilty to four charges in a west London court today, including two of assaulting the po-po and one \"public order offense.\" Her rep... <a href=\"http://www.tmz.com/2008/06/20/naomi-cops-to-clobbering-coppers/\">Read more</a><br/><br/>",
             :thumb_path=>nil}

    post = posts.find{|p| p[:link] == first[:link]}
    first.each do|k,v|
      pv = post[k]
      pv.should == v
    end

    second = {:summary=>"<p>Filed under: <a href=\"http://www.tmz.com/category/wacky-and-weird/\" rel=\"tag\">Wacky &amp; Weird</a></p><a href=\"http://www.tmz.com\">TMZ.com</a>: Katie Couric made it clear -- she's pretty damn close with the hot guy she went to lunch with on Robertson yesterday ... but not that close!Who do you think she is, Angelina?\n\nSee Also\n\n    Katie Couric -- Hoity-Toity!\n\n... <a href=\"http://www.tmz.com/2008/06/20/katie-couric-incest-aint-my-thing/\">Read more</a><br/><br/>",
              :published_at=>"2008-06-20T09:25:00+00:00",
              :body=>"Katie Couric made it clear -- she's pretty damn close with the hot guy she went to lunch with on Robertson yesterday ... but not <em>that </em>close!Who do you think she is, Angelina?",
              :author=>"TMZ Staff",
              :link=>"http://www.tmz.com/2008/06/20/katie-couric-incest-aint-my-thing/",
              :title=>"Katie Couric -- Incest Ain't My Thing!",
              :image=>'/images/video.png',
              :tag_list=>["katie couric", "KatieCouric"],
              :thumb_path=>nil}
    post = posts.find{|p| p[:link] == second[:link]}

    second.each do|k,v|
      pv = post[k]
      pv.should == v
    end

    last = {:summary=>"<p>Filed under: <a href=\"http://www.tmz.com/category/britney-spears/\" rel=\"tag\">Britney Spears</a></p><a href=\"http://www.tmz.com\">TMZ.com</a>:  We're told new daddy Casey Aldridge was so nervous the first time he held his daughter, he told the family he was scared he'd drop her!TMZ spies say that Casey and Mama Lynne were the only ones in the OR when Maddie was born -- Brit Brit waited... <a href=\"http://www.tmz.com/2008/06/19/careful-daddy-thats-a-live-one/\">Read more</a><br/><br/>",
            :published_at=>"2008-06-19T17:53:00+00:00",
            :body=>"We're told new daddy Casey Aldridge was so nervous the first time he held his daughter, he told the family he was scared he'd drop her!TMZ spies say that Casey and Mama Lynne were the only ones in the OR when Maddie was born -- Brit Brit waited outside anxiously. We hear that the family is thrilled that baby Maddie is \"happy, healthy and gorgeous\" and our source says the family is closer than ever. Jamie Lynn is expected to remain in the hospital for a few days, but big sis is already back at the house with her fast food fix.",
            :author=>"TMZ Staff",
            :link=>"http://www.tmz.com/2008/06/19/careful-daddy-thats-a-live-one/",
            :title=>"Careful Daddy, That's a Live One!",
            :video=>false,
            :tag_list=>["Casey Aldridge", "CaseyAldridge", "Jamie Lynn Spears", "JamieLynnSpears"],
            :thumb_path=>File.expand_path(File.join(File.dirname(__FILE__),"../../staging/www.blogsmithmedia.com/www.tmz.com/media/2008/06/thumbs/0619_jamie_casey_more_details.jpg"))}

    post = posts.find{|p| p[:link] == last[:link]}

    last.each do|k,v|
      pv = post[k]
      pv.should == v
    end

    #puts "check images #{images.inspect}"

    count = 0
    missing = 0
    images.each_with_index do|pic,i|
      if File.exist?("#{stage_root}/#{pic}")
      count += 1
      else
        #puts "missing '#{stage_root}/#{pic}'"
        missing += 1 # image 0620_kid_launch.jpg is no longer available... but we don't crash so this is good...
      end
    end
    count.should == (images.size-1)
    missing.should == 1
  end

end

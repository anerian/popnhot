require File.dirname(__FILE__) + '/helper.rb'

describe 'Extracting PopSugar Content' do
  before(:each) do
    @session = {}
    @crawl = Crawl::PopSugar.new(DIR_ROOT,@session,{},'',NewsFeed::RSS)
  end

  it 'should extract the content area' do
    @session.expects(:request).with('http://images.teamsugar.com/files/upl1/0/88/29_2008/parishilton71608.jpg').returns(nil)
    extracted = @crawl.extract(fixture('www.popsugar.com/1790036'),
                               URI.parse('http://www.popsugar.com/1790036'), %{<p>Paris Hilton wasn't looking like her usual <a href="http://popsugar.com/1778785" >smiley self</a> as she made her way out of CocoDeVille Lounge in LA last night. Maybe she was lonely without Benji on her arm, or it could be that she's still trying to fight off her most recent headlines.  On Monday, Paris took to her <a href="http://blog.myspace.com/index.cfm?fuseaction=blog.view&amp;amp;friendID=6459682&amp;amp;blogID=414816962" target="_blank">MySpace blog</a> to refute the rumors that <a href="http://popsugar.com/1784539" >she's causing trouble living next door to Nicole</a>. She also states that she plans on using her blog to set the record straight anytime she needs to from now on. Now, the question is whether to believe her or if she's <a href="http://popsugar.com/843188" >just trying to cover for herself</a>.  </p>
<p><a href="/gallery/551377" target="gallery"><span class="inline left"><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/parishilton71608.jpg" alt="" title="" class="image preview" width="550" height="401"></span></a></p>
<p><p>					<div id=mask-88008 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2 active ' href=http://popsugar.com/gallery/551377?page=0,0,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton02wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-94733 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,1,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton01wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-89902 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,2,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton06wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-13164 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,3,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton03wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-39202 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,4,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton04wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-60819 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,5,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton07wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 							<div id=mask-59519 class=mask style='float:left;width:75px;height:75px;overflow:hidden;background:#FFF;margin:0px 3px 3px 0px;border:0px solid #111;padding:0px;' onmouseover={style.borderColor='#ff3399'} onmouseout={style.borderColor='#111'}>
					<div style='margin-left:0px;margin-top:0px;padding:0px;'>
			 		<a target=gallery3 class='thumb2  ' href=http://popsugar.com/gallery/551377?page=0,6,0><img src="http://images.teamsugar.com/files/upl1/0/88/29_2008/23514PCN_Hilton05wtmk.smallsquare.jpg" alt="image" title="image"  class="image smallsquare" width="75" height="75" /></a>
			 		</div>			 		
			 		</div>
			 		</p><br clear=all></p>
<p><a href="http://pacificcoastnewsonline.com/" target="_blank">Pacific Coast News Online</a></p>
<p><a href="http://feeds.feedburner.com/~a/popsugar?a=eR9Hh4"><img src="http://feeds.feedburner.com/~a/popsugar?i=eR9Hh4" border="0"></img></a></p><img src="http://feeds.feedburner.com/~r/popsugar/~4/337291880" height="1" width="1"/>
                               })
    extracted.should_not == nil
    body = extracted[:body]
    #puts extracted.inspect
  end

end

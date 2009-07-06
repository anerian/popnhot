require 'fileutils'
require 'uri'
require 'rubygems'
require 'curb'

easy = Curl::Easy.new

prefix = "/Users/taf2/work/feedlog/popnhot/feed_crawler/specs/mocks"
=begin
["#{prefix}/www.tmz.com/2008/06/20/fiddy-to-ex-sh-sh-sh-shut-your-trap",
"#{prefix}/www.tmz.com/2008/06/20/courtney-keeps-her-britney-covered-sorta",
"#{prefix}/www.tmz.com/2008/06/20/helena-bonham-carter-looks-like-sheet",
"#{prefix}/www.tmz.com/2008/06/20/beach-bods-the-dudes",
"#{prefix}/www.tmz.com/2008/06/20/siennas-ex-hits-the-bottle-and-hits-with-it",
"#{prefix}/www.tmz.com/2008/06/20/tim-mcgraw-livin-the-good-slice",
"#{prefix}/www.tmz.com/2008/06/20/keyshawn-to-javon-ice-got-you-cold-cocked",
"#{prefix}/www.tmz.com/2008/06/20/judge-kicks-fiddy-to-the-curb",
"#{prefix}/www.tmz.com/2008/06/20/doesnt-jamie-lynn-know-no-glove-no-love",
"#{prefix}/www.tmz.com/2008/06/20/uk-says-marthas-a-bad-thing",
"#{prefix}/www.tmz.com/2008/06/20/kid-rock-my-craps-for-the-taking",
"#{prefix}/www.tmz.com/2008/06/20/denise-richards-marches-into-court",
"#{prefix}/www.tmz.com/2008/06/20/hubby-to-mel-b-suck-it-in-sister",
"#{prefix}/www.tmz.com/2008/06/20/baby-mama-to-fiddy-dont-you-touch-my-baby",
"#{prefix}/www.tmz.com/2008/06/20/katie-couric-incest-aint-my-thing",
"#{prefix}/www.tmz.com/2008/06/20/searching-high-and-lowe-for-nanny-3-0",
"#{prefix}/www.tmz.com/2008/06/20/phillys-crazaziest-i-got-teed-up-on-dr-phil",
"#{prefix}/www.tmz.com/2008/06/20/naomi-cops-to-clobbering-coppers",
"#{prefix}/www.tmz.com/2008/06/20/what-the-chuck-barkley-pokering-again",
"#{prefix}/www.tmz.com/2008/06/19/careful-daddy-thats-a-live-one"].each do|p|
  FileUtils.mkdir_p(File.dirname(p))
  File.open(p,"w")do|f|
    #f << %{<html><body><p class='body'>sample needs to be requested</p></body></html>}
    easy.url = p.gsub(/#{prefix}\//,'http://')
    easy.on_body{|data| f << data; data.size }
    easy.perform
  end
  puts p
end
=end
["http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0619_jamie_casey_more_details.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/picture-184.png",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/picture-185.png",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/picture-186.png",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/picture-188.png",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_fifty_shaniqua.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_denise_launch.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_kid_launch.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_stewart_bn.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_50_shaniqua_exl.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_faith_tim_splash_02.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0617_guys_launch.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_helena_bonham_carter_ramey_01.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_courtney_love_ramey.jpg",
"http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0620_panty_raid2.jpg"].each do|url|
  uri = URI.parse(url)
  path = File.join(prefix,uri.host,uri.path)
  FileUtils.mkdir_p(File.dirname(path))

  File.open(path,"w")do|f|
    easy.url = url
    easy.on_body{|data| f << data; data.size }
    easy.perform
  end
  puts "#{url} => #{path}"
end

require File.join(File.dirname(__FILE__),'dist.all.last')
require File.join(File.dirname(__FILE__),'dist.all.first')
require File.join(File.dirname(__FILE__),'dirty.words')
require 'rubygems'
require 'rbtagger'
require 'stemmer'
require 'activesupport'

module Normalize
  StopWords = Set.new([
         :I,
         :a,
         :about,
         :an,
         :are,
         :as,
         :at,
         :be,
         :by,
         :com,
         :de,
         :en,
         :for,
         :from,
         :how,
         :in, 
         :is, 
         :it,
         :la,
         :of,
         :on,
         :or,
         :that,
         :the ,
         :this,
         :to,
         :was,
         :what,
         :when,
         :where,
         :who,
         :will, 
         :with,
         :und,
         :the,
         :www ]).freeze

  class Tags
    def self.prepare_text(text)
      text = ActiveSupport::Multibyte::Chars.new(text).mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').
                                            to_s.gsub(/\r|\n/,' ').gsub(/\s/, ' ').squeeze(' ')
    end

    def self.name_taggers
      [Word::Tagger.new( Names::First.all.map{|n| n.to_s.downcase.gsub(/_/,' ')}, :words => 1 ),
      Word::Tagger.new( Names::Last.all.map{|n| n.to_s.downcase.gsub(/_/,' ')}, :words => 1 )]
    end

    def self.extract(text, rule_tagger, first_tagger, last_tagger)
      tag_list = rule_tagger.suggest(Normalize::Tags.prepare_text(text)).map{|tt| tt.first }
      doc = nil
#      puts "rule tagger: #{tag_list.inspect}"

      tag_list = (tag_list||[]).map{|n| Normalize::Tags.normalize(n).downcase }.uniq

      # in addition to what the rule tagger found, lets do a simple search for first names and see if the last name follows...
      words = text.split(' ')
      words.each_with_index do|w,i|
        if w[0].chr.to_s.match(/[A-Z]/) and !StopWords.include?(w.to_sym) and Names::First.include?(w) and words.size > i
      #    puts "word is first '#{w.inspect}' what about #{words[i+1]}"
          if Names::Last.include?(words[i+1])
            tag_list << "#{w} #{words[i+1]}"
          end
        end
      end
      tag_list = (tag_list||[]).map{|n| Normalize::Tags.normalize(n).downcase }.uniq
#      puts "Possible tags: #{tag_list.inspect}"
      tag_list = Normalize::Tags.selective(tag_list, first_tagger, last_tagger).join(',')
#      puts "Selective tags: #{tag_list.inspect}"
      tag_list
    end

    def self.normalize(tag)
      tag = prepare_text(tag)
      ns = ''
      caps=0
      tag.split('').each do|c|
        if c.match(/[A-Z]/)
          ns << " #{c}"
          caps += 1
        else
          ns << c
        end
      end
      if caps > 2 and tag.size < 7
        tag.downcase.strip.gsub(/\s+/,' ')
      else
        ns.downcase.strip.gsub(/\s+/,' ')
      end

    end

    def self.selective(tags, first_tagger, last_tagger)
      result_tags = []

      # first pass be very selective only pick up tags that have a first and last name match
      for tag in tags do
        frt = first_tagger.execute(tag)
        lrt = last_tagger.execute(tag)
        if frt.any? and lrt.any? # keep the tag
#          puts "frt:#{frt.inspect} lrt:#{lrt.inspect} -> #{tag}"
          # look at the word order and discard words or keep words based on matching order
          words = tag.split(' ')
          next if words.size > 3
          saved = []
          words.each {|w| saved << w if frt.include?(w) or frt.include?(w.stem) or Names::First.include?(w) }
          words.each {|w| saved << w if lrt.include?(w) or lrt.include?(w.stem) or Names::Last.include?(w) }
          saved.uniq!
#          puts "use: #{saved.inspect}"
          result_tags << saved.join(' ')
        end
      end
      if result_tags.empty?
        # be much less selective
        for tag in tags do
          frt = first_tagger.execute(tag)
          lrt = last_tagger.execute(tag)
          if frt.any? or lrt.any? # keep the tag
            result_tags << tag
          end
        end
      end
      result_tags.uniq
    end

  end
end

if defined?(TagList)
  TagList.class_eval do
    def add(*names)
      extract_and_apply_options!(names)
      concat((names||[]).map{|n| Normalize::Tags.normalize(n) }.uniq)
      clean!
      self
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class VerifyTest < Test::Unit::TestCase
    def test_spears_kfed
      tags = ['britney spears', 'BritneySpears', 'k-fed', 'kevin federline', 'KevinFederline'].map do|t|
        Normalize::Tags.normalize(t)
      end.uniq
      assert_equal ["britney spears", "k-fed", "kevin federline"], tags
    end

    def test_guns_n_roses
      tags = ["dave  weintraub", "dave weintraub", "guns  n  roses", "guns n roses", "steven  adler", "steven adler"]
      ntags = tags.map{|t| Normalize::Tags.normalize(t) }.uniq
      assert_equal ["dave weintraub", "guns n roses", "steven adler"], ntags
    end

    def test_chars
      tags = ["Penélope Cruz"]
      ntags = tags.map{|t| Normalize::Tags.normalize(t) }.uniq
      assert_equal ["penelope cruz"], ntags
    end

    def test_selective
      first_tagger, last_tagger  = Normalize::Tags.name_taggers

      tags = ["dave  weintraub", "dave weintraub", "guns  n  roses", "guns n roses", "steven  adler", "steven adler"]
      ntags = tags.map{|t| Normalize::Tags.normalize(t) }.uniq
      assert_equal ["dave weintraub", "guns n roses", "steven adler"], ntags
      puts Normalize::Tags.selective(ntags, first_tagger, last_tagger).inspect
      tags = ["katherine jackson", "tuesday", "prince michael", "children", "related michael jackson"]
      selected = Normalize::Tags.selective(tags, first_tagger, last_tagger)
      puts selected.inspect
    end

    def test_extract_tricky
      tagger       = Brill::Tagger.new
      first_tagger, last_tagger  = Normalize::Tags.name_taggers
      # Poppy isn't a noun or detected as such in this sentence...
      text = %("No, Poppy Montgomery hasn't let herself go since her long-running CBS drama, Without a Trace, wrapped up production last spring. The normally svelte star is just filming Cinderella Pact, a comedy set to air on the Lifetime Movie Network in 2010. Currently shooting in Vancouver, Cinderella is about a frumpy magazine editor who lives a double life as an glamorous and reclusive advice columnist. She ultimately drops several dress sizes during the film. There's no word yet on whether her Cinderella character will be bikini-ready by the end of the film, but she celebrated losing her 70 lbs. of baby weight after son Jackson by posing in a tiny green bikini for PEOPLE last year!  PHOTOS: The Obama's Russian Double Date  WATCH: Debbie Rowe Yells At Paparazzi ")
      tags = Normalize::Tags.extract(text, tagger, first_tagger, last_tagger)
      puts "Poppy? #{tags.inspect}"
    end

    def test_extract
      samples = {
#              %(No, Poppy Montgomery hasn't let herself go since her long-running CBS drama, Without a Trace, wrapped up production last spring. The normally svelte star is just filming Cinderella Pact, a comedy set to air on the Lifetime Movie Network in 2010. Currently shooting in Vancouver, Cinderella is about a frumpy magazine editor who lives a double life as an glamorous and reclusive advice columnist. She ultimately drops several dress sizes during the film. There's no word yet on whether her Cinderella character will be bikini-ready by the end of the film, but she celebrated losing her 70 lbs. of baby weight after son Jackson by posing in a tiny green bikini for PEOPLE last year!  PHOTOS: The Obama's Russian Double Date  WATCH: Debbie Rowe Yells At Paparazzi 
#              )  => ["poppy montgomery"],
              %(Corey Feldman Mirrors Michael Jackson Corey Feldman has said he's "shaken up" by the death of his friend and idol Michael Jackson. To pay homage to the late, great star, Feldman has twice dressed in a Jackson-style outfit. On Tuesday, the actor showed up to mourn his old friend at the Michael Jackson Memorial Concert at the Staples Center in L.A. wearing a faux-military jacket, shades, and a black fedora. Just two days after Jackson's death, during Feldman's L.A. concert with his band Truth Movement, the actor told the audience he wanted to honor "the world's greatest entertainer" with a moment of silence – all while dressed in a Jackson-style buttoned regal jacket.Rocky PastFeldman, 37, and Jackson became friends when Feldman was a teenager but had drifted apart by the time the pop star died at age 50. "Unfortunately Michael and I had a falling out on September 10th 2001 and that broken friendship had never been repaired," Feldman said in a statement on the day of Jackson's death. "All I choose to remember from this point is the good times we shared and what an inspiration he was to me and the rest of the world." Despite his rocky relationship with Jackson, Feldman remained friendly with the Jackson family, attending LaToya's birthday party recently with Feldman's wife Susie. "What [Michael] taught me is that you always have to be nice to your fans and always treat them with love and respect," Feldman told PEOPLE last month. "Even if you don't remember the moment, they are always going to remember that moment. That's something that I carry with me."  PHOTOS: Suri, Tom & Katie Go To The Theater  The Best Underrated Summer Movies
              ) => ["corey feldman", "michael jackson"] }
=begin
              %(After the Cruise clan did some high-profile celebrating in Australia last week, the ladies of the family took time out to spend a relaxing day by the pool. With Tom Cruise checking out of the Melbourne hotel Tuesday, wife Katie Holmes and their 3-year-old daughter Suri remained "very much in residence" at their luxury digs, according to a source. Dressed in a flattering tangerine one-piece swimsuit, Holmes played with Suri who held onto a blue floatation noodle in the indoor pool. The duo spent time in the spa, then headed to the larger pool where they were surrounded by local Melbourne children vacationing with their families."Suri looked so cute," said Felix Mason, 14, who was relaxing in the pool and spa area. "Even before I realized it was her I had thought she was an adorable little girl.” Another guest, William Cuthbertson, 9, said he recognized Holmes from 2005's Batman Begins. "Suri was tucked up against Katie's chest and she wouldn't show her face to us," he said. Holmes smiled at the others and wrapped her daughter in a fluffy white towel. Holmes, looking trim, put on an oversized gray shirt from the musical The Jersey Boys, which the family saw during at a Sunday matinee. Holmes is preparing to start shooting Don't Be Afraid of the Dark in Melbourne this month. On Friday, the family celebrated Tom's 47th birthday by watching an Australian football match from a private box  PHOTOS: Suri, Tom & Katie Go To The Theater  The Best Underrated Summer Movies
              ) => ["tom cruise"],
              %(At today's memorial to Michael Jackson at the Staples Center, Mariah Carey performed the Jackson 5 hit "I'll Be There" with Trey Lorenz.
              ) => ["michael jackson"],
              %(With toxicology tests still being conducted, Michael Jackson's cause of death is listed as "deferred" on his official death certificate, which was issued Tuesday, the same day as his private funeral and public memorial.  PHOTOS: Suri, Tom & Katie Go To The Theater  The Best Underrated Summer Movies
              ) => ["michael jackson"],
              %(Corey Feldman shows up to Michael Jackson's memorial wearing something straight out of MJ's closet.
              ) => ["corey feldman"],
              %(Michael Jackson's daughter Paris, 11, paid tribute to her father at the end of the singer's memorial Tuesday at L.A.'s Staples Center. Fighting back tears, she approached the microphone with the help of Janet Jackson (who told her gently to "speak up").  "Ever since I was born, daddy has been the best father you could ever imagine," she said. Before leaving the stage, she added: "I just wanted to say I love him so much." Jackson's other two kids, Prince Michael, 12, and Blanket, 7, took the stage prior to join others in a sing-along of "We Are the World/Heal the World." Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!
              ) => ["michael jackson", "janet jackson"],
              %( 8:01 a.m.: Jesse Jackson is the first celeb to hit the row of press stand-ups.  9:06 a.m.: Stage has double podiums, double drum sets. Jackson's song "Rock With You" is playing on a speaker. As guests enter Staples, they are given a 14-page color program with personalized notes from the family and loved ones. The program features photos of Jackson from all phases of career. "My brother developed a shoe that showed resistance to gravity. What a man!" reads Tito Jackson's comment. Latoya's comment reads, "You've done your work here, Michael. You've entertained us for decades and there's nothing else that you can prove or accomplish here on earth. Mike. I love you deeply \(sic\) and I can't wait to see you perform again. Keep the magic going!!!" The centerfold in Staples is a collage of Jackson with celebs, including past presidents Bush, Clinton, Reagan. There are a lot of shots of Jackson with Elizabeth Taylor. 9:25 a.m.: Smokey Robinson, in a gray suit, is up front talking to security. 9:29 a.m.: Spike Lee talking with Smokey Robinson in front of the stage. A forlorn Queen Latifah is draped in a shawl approaching the stage. 9:34 a.m.: The entire Kardashian family arrives. Kim tells Us: "It's just really important to be here to support the Jackson family. My family and I have known them for years, so it's really special to be here for them." 9:38 a.m.: Larry King and his wife, both in all black and walking arm-in-arm, are escorted inside Staples Center. 9:40 a.m.: Jesse Jackson arrives in an Escalade with a group of people. 9:44 a.m.: Louis Farrakhan arrives with an entourage of 15. 9:45 a.m.: As Elizabeth Berkley arrives, Diff'rent Strokes star Todd Bridges tells Us: "I knew him - that's why it's special to be here. He was the greatest superstar, and I knew him every since I was a little kid, for many, many years, you know? I'm here to honor him." 9:45 a.m.: Jackson's hearse arrives at Staples Center 9:52 a.m.: "Ladies and gentlemen, please take your seats," an announcer says as the Staples Center goes silent. "The service will begin very very shortly." Meanwhile, the outside of Staples Center has cleared.  Inside, the family floor section is less than half-full. Most of the guests are in traditional funeral wear, not crazy fan costumes. Surprisingly, many in family section are wearing all white. 9:56 a.m.: Rev. Al Sharpton is deep in conversation with John Mayer, whom he is seated next to, and director Tyler Perry. 9:58 a.m.: Barbara Walters is chatting with Magic Johnson. Mike Tyson is present. 10:00 a.m.: Nicky Hilton is seated with her mother and father. "Michael was a good family friend," she tells Us. "This is a part of history." 10:01 a.m.: Dionne Warwick is mingling with Kobe Bryant. 10:12 a.m.: Smokey Robinson addresses the crowd; he reads statements from Diana Ross and Nelson Mandela. Ross' statement reads: "Thank you, Katherine and Joe for sharing your son with the world. I share my love and condolences with the Jackson family." 10:16 a.m.: Usher arrives late, wearing a yellow rose. He kisses Brooke Shields on the cheek before taking his seat. 10:17: John Mayer and Brooke Shields briefly chat. She's sitting right in front of him. 10:19 a.m.: Corey Feldman enters dressed as Michael Jackson. He wipes tears from under his sunglasses. 10:20 a.m.: Al Sharpton and Jesse Jackson exchange greetings. 10:20: Diddy and Jennifer Hudson take their seats. 10:21: The Jackson family enters and receives a standing ovation.  10:33 a.m.: As a church choir sings "We Are Going to See the King," Jackson's red rose-covered casket is brought inside and set on the stage. The crowd cheers and gives a standing ovation. His brothers serve as pallbearers and wear sparkly silver gloves. 10:34 a.m.: Spike Lee takes photos with his digital camera. 10:35 a.m.: Chris Tucker enters as the choir is singing. 10:37 a.m.: Pastor Smith delivers a service. "Our hearts are heavy today because...he's gone far too soon," he says. 10:39 a.m.: Mariah Carey, in a black gown by Jenny Packham, sings the Jackson 5 hit "I'll Be There." She is joined by Trey Lorenz. Images of Jackson 5 flash on the screen behind them. 10:44 a.m. Queen Latifah says, "Somehow, when Michael Jackson sang, when he danced, you never felt distance. You felt like you were right there...I loved him all my life... Michael was the biggest star on earth." She then quoted Maya Angelou. 10:50 a.m.: Lionel Richie sings "Jesus Is Loved" 11:01 a.m.: Motown Founder Berry Gordy speaks: "Thank you for the joy. Thank you for the heart. You will live in my heart forever." 11:04 a.m.: A montage of Jackson's music videos plays as the crowd cheers. The arena is dark; only Jackson's coffin is lit up. 11:07 a.m.: Stevie Wonder says, "This is a moment that I wish I didn't live to see coming. But as much as I can say that we mean it, I do know that God is good...Michael, I love you, and I've told you that many times." He performed "Never Dreamed You'd Leave in Summer." 11:13 a.m.: Kobe Bryant and Magic Johnson take the stage. "Because he gave so much to so many for us, Michael Jackson remains with us forever," Bryant says. Johnson recalled appearing in Jackson's video for "Remember the Times." He went to Jackson's house to discuss ideas. "We had such a good time sitting on the floor eating Kentucky Fried Chicken," he said. Johnson also brought up Jackson's children: Prince Michael, 12, Paris, 11 and Blanket, 7, who are under the temporary custody of Katherine. "Those three children will have the most incredible grandmother that God has put on this earth to take care of them. Michael's three children will have incredible uncles and aunts to take care of them as well...and cousins!" 11:20 a.m.: A pregnant Jennifer Hudson sings "Will You Be There." 11:26 a.m.: Al Sharpton discusses the Jackson's upbringing in Gary, Indiana and eulogizes Jackson.  11:34 a.m.: John Mayer performs "Human Nature" as the crowd claps along. After, he hugs Jackson's brothers. 11:39 a.m.: Brooke Shields fights back tears. "Michael was one of a kind...Michael always knew he could count on me to be his date. Michael tried in vain one night to unsuccessfully teach me the Moonwalk. Michael loved to laugh. MJ's laugh was the sweetest and purest laugh. His sense of humor was delightful, and he was very mischievous." She stopped for an extra moment to look at Jackson's casket on stage before returning to her seat in row 7. 11:48 p.m.: Jermaine Jackson performs Charlie Chaplin's "Smile," which is Michael's favorite song, Shields says at the service. After, he took his flower boutonniere off his lapel, and tossed it on the coffin. 11:51 a.m.: Bernice King and Martin Luther King III speak. After quoting his father, King III said: "Michael Jackson was truly the best." Bernice recalled when Michael called their ailing mother from the Middle East to let her know he was praying for her. 11:59 a.m.: Texas congresswoman Sheila Jackson Lee of the congressional black caucus speaks. "We are the world, and we are better because Michael Joseph Jackson lived...I salute you." 12:07 p.m.: Usher places his hand on Jackson's casket while singing "Gone Too Soon." Photos of Jackson as a child flash on the screen behind him. After, he hugged Jackson's brothers and broke into sobs. He then kneeled down to speak to Katherine and Joe before returning to his seat. 12:13 p.m. Britain's Got Talent star Shaheen Jafargholi sings "Who's Lovin' You" and says, "I love Michael Jackson. I just want to thank him so much for blessing me and every single individual on this earth." 12:23 p.m.: Kenny Ortega, who was directing Jackson's comeback tour, calls Jackson a "living legacy" before introducing a group to sing "We Are the World." Jackson's daughter Paris sings. Lionel Richie and Jennifer Hudson are also on stage. Children and additional celebs then take the stage to sing "Heal the World." Blanket stands in front of Janet Jackson. Paris -- who is standing in front of LaToya Jackson -- kisses Blanket's hands. Paris, Prince and Blanket sing along. 12:31 p.m.: Prince has his arm around Paris, who is holding Blanket.  Jermaine and Marlon speak. Paris puts a tissue in her handbag, and leans on Janet. Paris then asks for the microphone. "I just wanted to say...ever since I was born, daddy has been the best father you could ever imagine...and I just wanted to say I love him so much," she says through sobs. Janet and several other family members lead her off the stage, which goes dark. 12:41 p.m.: Michael's casket is rolled out by family members as "Man in the Mirror" plays. 12:48 p.m.: Jackson family friend Pastor Lucius Smith reads a benediction and the memorial draws to a close. Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "jesse jackson", "tito jackson", "todd bridges", "elizabeth taylor", "smokey robinson", "diana ross", "nelson mandela", "usher"],
              %(Michael Jackson Memorial -- Inside Staples Center A shot of the stage inside Staples Center as they prepare for the memorial service later this morning.
              ) => ["michael jackson"],
              %(As a squadron of news helicopters hovered, Michael Jackson's family and close friends mourned the pop star at a private funeral Tuesday morning. A hearse carrying his flower-covered casket then joined a motorcade headed to the public memorial at the Staples Center. In a spectacle carried live on television, authorities shut down freeways at the peak of rush hour to make way for the Rolls-Royces and Escalades traveling first to the funeral at Forest Lawn in the Hollywood Hills and then to the memorial in downtown Los Angeles. Thousands began streaming into the cavernous sports and concert arena, getting 15-page programs with a message from Jackson's sister Janet: "I miss you Mike and I love you."The memorial follows the private funeral that lasted less than a half hour in the 1,200-seat Hall of Liberty auditorium at Forest Lawn, a cemetery flanked by the Disney and Warner Bros. studios. Starting at 6:30 a.m., mourners traveled by police-escorted motorcade from the Jackson family compound in Encino across the San Fernando Valley. The night before, a smaller group of the Jackson clan gathered oat the cemetery. After the funeral, Jackson's casket, decorated with red, white and yellow roses, was loaded into the hearse, and the motorcade traveled across unusually barren freeways cleared by CHP motorcycle officers. People gawked from the hillsides and overpasses. The star-studded tribute reportedly will serve as a combination gala celebration and somber funeral for Michael Jackson. Those scheduled to take the stage include Mariah Carey, Jennifer Hudson, Usher, John Mayer and Stevie Wonder. The Rev. Al Sharpton is to deliver the eulogy, reported NBC News.  Reporting by OLIVER JONES and JOHNNY DODDStay with PEOPLE.com for continuous updates on the Michael Jackson memorial scheduled for 1 p.m. Eastern time.  PHOTOS: Suri, Tom & Katie Go To The Theater  The Best Underrated Summer Movies
              ) => ["michael jackson", "jesse jackson"],
              %(Penélope Cruz is a perfectionist in all areas of her profession, something the Spanish-born star admits she carries over into her personal life. "Every time I make a film, I feel like it's my first time ... I always think they could fire me," the Oscar winner, 35, tells the August issue of Psychologies magazine in the U.K. "I've ruined my own happiness and created problems with my friends because of this tendency. It takes discipline for me to stop worrying." She adds, "I have a tendency to become a mother to everyone around me. My brother and sister are always complaining that I'm too protective."Someday that might just come in handy. Currently linked to fellow Spaniard Javier Bardem – about whom Cruz would only say, "He's a wonderful man, a great actor" – she does admit that she definitely desires kids. "I want to have babies one day but not right now. When I do it I want to do it really well. I want it to be my best project in life," says Cruz. "I don’t know if I believe in marriage. I believe in family, love and children." Appropriately enough, Cruz's next film is kid-friendly. She voices a gerbil spy named Juarez in Disney's G-Force, which hits theaters July 31.  PHOTOS: Suri, Tom & Katie Go To The Theater  The Best Underrated Summer Movies
              ) => ["penelope cruz"],
              %(Diana Ross has issued the following statement after missing Michael Jackson's memorial Tuesday at L.A.'s Staples Center: "I am trying to find closure, I want you to know that even though I am not there at the Staples Center, I am there in my heart. I have decided to pause and be silent. This feels right for me. Michael was a personal love of mine, a treasured part of my world, part of the fabric of my life in a way that I can't seem to find words to express," her statement began. In his will, Jackson named Ross as a backup guardian to his three children, Prince Michael, 12, Paris, 11, and Blanket, 7. In her statement, Ross said, "Michael wanted me to be there for his children, and I will be there if ever they need me." "I hope, today brings closure for all those who loved him," her statement concluded. "Thank you Katherine and Joe for sharing your son with the world and with me, I send my love an condolences to the Jackson family." Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!
              ) => ["michael jackson", "diana ross"],
              %(A helicopter landed at Neverland Ranch just a short while ago -- and another just hovered -- but Michael Jackson's body wasn't in either of them.Here's what we do know: it was part of some kind of interview about the ownership of Neverland, done by a media outlet that will air tomorrow. They requested to use Neverland as the backdrop and permission was granted.
              ) => ["michael jackson"],
              %(Michael Jackson Burial Mystery We've learned body will not be going back to Forest Lawn.The body will go somewhere else pending final burial -- we don't know where that is. If a casket goes to Forest Lawn, it's a decoy.We've learned the death certificate lists Forest Lawn as the responsible mortuary because the body was embalmed there -- but the rest is being kept secret.
              ) => ["michael jackson"],
              %(Michael Jackson -- #7 Get ready to have your mind blown. Ready? Here we go ...-- Michael Jackson signed his will on 7/7/02.-- Michael Jackson's memorial was on 7/7/09 ... exactly 7 years after the will was signed.-- Michael Jackson's two biggest hits -- "Black & White" and "Billie Jean" -- were each #1 for 7 weeks. -- Michael Jackson's three biggest albums -- "Thriller," "Bad" and "Dangerous" -- each produced 7 top 40 hits. -- Michael Jackson was the 7th of 9 children.-- Michael Jackson was born in 1958 ... 19 + 58 = 77-- Michael Jackson died on the 25th ... 2 + 5 = 7-- Michael Jackson has 7 letters in his first and last name.If you're looking for lottery numbers tonight, we recommend something with the number 7 in it.
              ) => ["michael jackson"],
              %(We've obtained a copy of Michael Jackson's death certificate. On cause of death, it says "deferred." It does say Forest Lawn Cemetery was a "temporary" disposition of the body. As we first reported the body will not go back to Forest Lawn. Final burial is pending at an unknown location.Jackson's occupation is listed as "musician." The type of business is "entertainment." Years in occupation -- 45.As for race, the word "black" is written.The informant -- the person who gave the information for the death certificate -- is listed as La Toya Jackson.The place of residence is not listed as the Holmby Hills home -- rather, it's listed as his parents' home in Encino.
              ) => ["michael jackson", "la toya jackson"],
              %(Michael Jackson's only daughter, 11-year-old Paris Michael Katherine, just gave an emotional speech at her father's memorial service -- saying he was the "best father you could ever imagine. I love him so much."
              ) => ["michael jackson", "paris michael katherine"],
              %(Mystery of Michael's Body Michael Jackson lived in mystery, so it's hardly a surprise his final resting place is a puzzle.We're told Jackson will not be buried at Forest Lawn. We checked with Neverland and with law enforcement in the area and it's almost certain the body won't be going there.We've also checked with various cemeteries in the L.A. area and so far we can't find any place where it looks like Jackson will be buried.There's a buzz the motorcade underway will be a decoy, but we can't confirm that.Stay tuned ...
              ) => ["michael jackson"],
              %(After over two hours of speeches and songs, Michael Jackson's poignant and sad memorial service has come to an end. Check out some of the memorial highlights.
              ) => ["michael jackson"],
              %(Fighting back tears, Brooke Shields addressed the crowd at Michael Jackson's memorial today, telling everyone MJ's favorite song was Charlie Chaplin's "Smile" -- and that's exactly what everyone needs to do on this day.
              ) => ["michael jackson", "brooke shields"],
              %(Magic Johnson -- MJ Was Finger Lickin' Good The "greatest moment" of
              ) => ["magic johnson"],
              %(Though she was not at the memorial service today, Diana Ross, who Micheal requested look after his kids in his will if his mother was unable to, released the following statement:"I am trying to find closure, I want you to know that even though I am not there at the Staples Center. I am there in my heart. I have decided to pause and be silent. This feels right for me. Michael was a personal love of mine, a treasured part of my world, part of the fabric of my life in a way that I can't seem to find words to express. Michael wanted me to be there for his children, and I will be there if they ever they need me. I hope, today brings closure for all those who loved him. Thank you Katherine and Joe for sharing your son with the world and with me. I send my love and condolences to the Jackson family."
              ) => ["michael jackson", "diana ross"],
              %(The guy who played Carmine "The Big Ragoo" Ragusa on "Laverne and Shirley" was arrested last Friday in Las Vegas after he allegedly got into a drunken car crash. Law enforcement sources tell us they received a call at around 12:30 PM about a collision with a "suspected drunk driver." When officers arrived, they found Eddie Mekka and administered field sobriety tests. After the tests, Mekka was placed under arrest for suspicion of driving under the influence -- a misdemeanor. As for the accident, we don't know any details, but we do know there were no injuries reported at the scene.
              ) => ["Eddie Mekka"],
              %(Here is the memorial service program for Michael Jackson being sold outside the Staples Center.
              ) => ["michael jackson"],
              %(There are various news reports that Michael Jackson's body is not in the casket -- absolutely not true.Our sources -- who know -- say 100% Jackson's body is in the coffin that is being taken to Staples Center.
              ) => ["michael jackson"],
              %(Michael Jackson signed his last will on 7-7-02, seven years to the day he will be memorialized and buried. Michael was the 7th in a family of 9 kids.
              ) => ["michael jackson"],
              %(Reverend Al Sharpton and Kobe Bryant together inside Staples Center at Michael Jackson's memorial.
              ) => ["michael jackson", "reverend al sharpton", "kobe bryant"],
              %(Usmagazine.com has obtained a copy of Michael Jackson's official death certificate, which lists his cause of death as "deferred," as toxicology tests are still underway. The certificate also says that Forest Lawn -- the site of a private viewing Monday and a family service Tuesday -- has "disposition" of the singer's body temporarily. The final resting place for the singer remains unknown. His sister Latoya Jackson provided the information on the death certificate, which lists him as a 50-year-old divorced black man; his occupation as "musician" and type of business as "entertainment."  The certificate was issued Tuesday, the same day as the singer's public memorial at L.A.'s Staples Center. Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!
              ) => ["michael jackson"],
              %(Corey Feldman showed up at Michael Jackson's public memorial Tuesday at L.A.'s Staples Center dressed as the King of Pop. He arrived at 10:19 a.m. dressed as the singer from his Dangerous era - wearing all black, a military-style jacket, a black fedora and sunglasses. He also had strands of his hair hanging in front of his face - a 'do Jackson famously sported. Feldman used a Kleenex to wipe tears from under his sunglasses. John Mayer gave him a puzzled look. "I've been crying a lot and I'm just drained," he told Us after the ceremony. "Michael changed the world and I think we should remember him for that." Asked about the funeral, "It was beautiful. Paris got me the most when she spoke."  Feldman befriended Jackson in the 1980s. The two had a rocky relationship during Feldman's teen years and eventually drifted apart. They didn't talk for several years before Jackson's death. After Jackson's June 25 death Feldman wrote on his website: "I am trembling and shaking at the moment and it is very hard to type. I am filled with tremendous sadness and remorse. All I choose to remember from this point is the good times we shared and what an inspiration he was to me and the rest of the world. Nobody will ever be able to do what Michael Jackson has done in this industry, and he was so close to doing it all again. I am truly, and deeply sorry for all of the heartbroken fans and supporters worldwide. I think I am still in shock. So I must end this now." Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "corey feldman"],
              %(Kim Kardashian says she couldn't keep her composure at Michael Jackson's memorial Tuesday in Los Angeles - especially when the late singer's daughter Paris, 11, took the stage. "I spoke at my dad's funeral & it was the hardest thing I've ever had to do," she Tweeted. "I was shaking & crying & what Paris did was sooo soooo brave!" She continued, "Michael's children were so brave brave 2 stand there on stage & speak to the world about their father." Kardashian went to the memorial with her sisters Kourtney and Khloe and her mother Kris Jenner, and "we all cried & laughed & remembered," she Tweeted. Usmagazine.com caught up with Kardashian at the memorial. She told Us: "It's just really important to be here to support the Jackson family. My family and I have known them for years, so it's really special to be here for them." Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!
              ) => ["michael jackson", "kim kardashian"],
              %(Michael Jackson celebrated his final Christmas with his three children -- and with dermatologist Arnold Klein, the biological father of Paris, 11, and Prince Michael I, 12. Us Weekly reports in its new issue on newsstands tomorrow that Klein brought Star Wars icon Carrie Fisher, a close friend, as a surprise guest for the kids to Jackson's $100,000-a-month Holmby Hills, Calif. rental. Fellow guest Stephen Price, a close friend of Klein's, tells Us Weekly that Jackson had mentioned to Klein that Paris, Prince and Prince Michael II \(a.k.a. "Blanket"\), 7, were fans of Star Wars and would like to meet Fisher. Around 9 p.m. on Christmas Eve, "Michael brought the kids down in their pajamas and said, 'This is Princess Leia,'" Price recalls. "They were so excited! She did her famous speech for them -- the 'Help me, Obi-Wan' speech." Price says of the Jackson kids, "They are the greatest kids you'll ever meet." As for Klein, who had employed Paris and Prince's mother, Debbie Rowe, for 23 years, Price would only say "no comment" about his longtime pal's status as their biological dad. Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "arnold klein", "carrie fisher"],
              %(Michael Jackson's 12-year-old son Prince Michael attended his late father's public memorial Tuesday at L.A.'s Staples Center (see photo, left). His other children, Paris, 11, and Blanket, 7, also attended. Prince Michael sat with his grandparents Joe and Katherine Jackson as a myriad of celebrities paid tribute to the King of Pop, who died at age 50 after suffering cardiac arrest June 25.  Katherine Jackson remains the children's temporary guardian. A hearing is set for July 13. Debbie Rowe, mother of Jackson's two eldest kids, has yet to announce if she will seek custody. "Those three children will have the most incredible grandmother that God has put on this earth to take care of them," said Magic Johnson at Tuesday's memorial. "Michael's three children will have incredible uncles and aunts to take care of them as well, and [plenty] of cousins!" Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "prince michael"],
              %(Brooke Shields says she "instantly became friends" with Michael Jackson after meeting him when she was 13. "Nothing was jaded about him. I just was so impressed by his sweetness," Shields tells 's special commemorative issue on the King of Pop, on stands Friday. "He was thoughtful, sensitive, sweet, and had a funny sense of humor," she goes on. "If you got to talk to him about music or about the future of technology, his voice would get deeper, he would start talking, and it was as if he was this genius." Sexuality didn't play a role in their relationship, she explains. "As he grew older and the more he started to change physically, the more asexual he became to me," Shields says. "It was easy for him to be a friend to me, because I was the most celebrated virgin ever; it's ridiculous, but I was America's virgin.  "You saw women who were more sexual, who wanted to throw themselves at him and feel like they were going to teach him; we just found each other, and we didn't have to deal with our sexuality. As I grew up and started having boyfriends, I would share with him, and he was like a little kid who talked about the bases- what first base was, what second base was, and it sounded very odd to the outside, I can imagine, but to the inside, to someone who's never really left his bubble, you can understand how he would be curious." Shields continues. "There were times when he would ask me to marry him, and I would say, 'You have me for the rest of your life, you don't need to marry me, I'm going to go on and do my own life and have my own marriage and my own kids, and you'll always have me.' I think it made him relax. He didn't want to lose things that meant something to him," she adds. She last saw Jackson at Elizabeth Taylor's 1991 wedding. "He seemed like his own funny self," she says. "We snuck in and took pictures of ourselves next to her dress. We always seemed to revert to being little kids. It was a sanctuary for him, because he knew I never wanted anything from him but his happiness." Shields is expected at the Staples Center memorial at 10 a.m. PST. Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "brooke shields"],
              %(Michael Jackson's casket has arrived at the Staples Center for a public memorial. It was covered with red roses and loaded into a hearse at 9:27 a.m. PST following a private service 10 miles away at the Forest Lawn Memorial Park. Family and friends spent a half hour at the service Tuesday morning. They arrived in a motorcade of Rolls-Royces, Bentleys, Range Rovers and Cadillacs from Katherine's home in Encino, Calif.  A star-studded memorial is expected to begin at 10:30 a.m. at the Staples Center. Fans, many dressed in all-white, are singing along to Jackson's songs. Spike Lee, Queen Latifah, Smokey Robinson and Kardashian family have also been spotted in the audience.  "It's just really important to be here to support the Jackson family," Kim Kardashian tells Usmagazine.com. "My family and I have known them for years so it's really special to be here for them." Mariah Carey, Usher and Jennifer Hudson are set to perform at the memorial for Jackson, who died June 25 of cardiac arrest. According to the UK Sun, Usher will sing Jackson's 1993 hit, "Gone Too Soon" as images of Jackson as a child flash on the screen behind him. A children's choir is also expected to sing his anthem, "We Are the World." More than 1.6 million people applied for the 17,500 available tickets at the Staples Center and neighboring Nokia Theater, which will simulcast the event. Join Us on Facebook and Twitter for even more up to the minute celebrity news and photos!        Related Michael Jackson Posts
              ) => ["michael jackson", "spike lee", "queen latifah", "smokey robinson"],
              %(La Toya, Paris and Katherine Jackson inside Michael's memorial at Staples Center.
              ) => ["michael jackson", "katherine jackson"] }
=end
      tagger       = Brill::Tagger.new
      first_tagger, last_tagger  = Normalize::Tags.name_taggers

      samples.each do|s,expected|
        tags = Normalize::Tags.extract(s, tagger, first_tagger, last_tagger)
        puts "expected: #{expected.inspect} - actual: #{tags.inspect}"
      end
    end
  end
end

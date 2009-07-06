require File.dirname(__FILE__) + '/helper.rb'

describe 'TMZ Parsing Content' do
  before(:each) do
    @session = {}
    @crawl = Crawl::Tmz.new(DIR_ROOT,@session,{},'',NewsFeed::RSS)
  end

  it 'should extract the content area' do
    extracted = @crawl.extract(fixture('www.tmz.com/liz-taylor-rollin-with-her-homies'),
                               URI.parse('http://www.tmz.com/liz-taylor-rollin-with-her-homies') )
    extracted.should_not == nil
    body = extracted[:body]
    body.should_not == nil

    body.should_not =~ /<a name="continuedcontents">/
    body.should_not =~ /<br\s*\/>/
    body.should_not =~ /<ul\s*\/>/
    body.should_not =~ /<ul\s*>/
    body.should_not =~ /<div class="related">/
    body.should_not =~ /<script.*?>/
  end

  it 'should find images for content when images are present' do
    uri = URI.parse('http://www.tmz.com/2008/06/30/monkey-flee-monkey-do')
    @session.expects(:request).with('http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0630_moe_the_chimp_missing.jpg').returns(nil)
    #@crawl = Crawl::Tmz.new(session,'',NewsFeed::RSS)
    extracted = @crawl.extract(fixture('www.tmz.com/2008/06/30/monkey-flee-monkey-do'), uri)
    extracted[:thumb_path].should == "http://www.blogsmithmedia.com/www.tmz.com/media/2008/06/0630_moe_the_chimp_missing.jpg"
  end

  it 'should identify posts with no image that include video' do
    extracted = @crawl.extract(fixture('www.tmz.com/liz-taylor-rollin-with-her-homies'),
                               URI.parse('http://www.tmz.com/liz-taylor-rollin-with-her-homies') )
    extracted[:thumb_path].should == nil
    extracted[:video].should == true
  end

  it 'should not fail if the document does not contain a p.body tag' do
    extracted = @crawl.extract(fixture('www.tmz.com/no_p_body'),
                               URI.parse('http://www.tmz.com/no_p_body') )
    extracted[:thumb].should == nil
    extracted[:video].should == false
    extracted[:body].should == "<p>no p body</p>"
  end

  it 'should not fail if the document is invalid markup to the point that hpricot raises some exceptions' do
    extracted = @crawl.extract(fixture('www.tmz.com/bad_html'),
                               URI.parse('http://www.tmz.com/bad_html') )
    #puts extracted.inspect
  end

end

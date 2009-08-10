require 'spec/spec_helper'

describe ThinkingSphinx::ActiveRecord::Scopes do
  after :each do
    Alpha.remove_sphinx_scopes
  end
  
  it "should be included into models with indexes" do
    Alpha.included_modules.should include(ThinkingSphinx::ActiveRecord::Scopes)
  end
  
  it "should not be included into models without indexes" do
    Gamma.included_modules.should_not include(
      ThinkingSphinx::ActiveRecord::Scopes
    )
  end
  
  describe '.sphinx_scope' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
    end
    
    it "should define a method on the model" do
      Alpha.should respond_to(:by_name)
    end
  end
  
  describe '.sphinx_scopes' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
    end
    
    it "should return an array of defined scope names as symbols" do
      Alpha.sphinx_scopes.should == [:by_name]
    end
  end
  
  describe '.remove_sphinx_scopes' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.remove_sphinx_scopes
    end
    
    it "should remove sphinx scope methods" do
      Alpha.should_not respond_to(:by_name)
    end
    
    it "should empty the list of sphinx scopes" do
      Alpha.sphinx_scopes.should be_empty
    end
  end
  
  describe '.example_scope' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.sphinx_scope(:by_foo)  { |foo|  {:conditions => {:foo  => foo}}  }
      Alpha.sphinx_scope(:with_betas) { {:classes => [Beta]} }
    end
    
    it "should return a ThinkingSphinx::Search object" do
      Alpha.by_name('foo').should be_a(ThinkingSphinx::Search)
    end
    
    it "should set the classes option" do
      Alpha.by_name('foo').options[:classes].should == [Alpha]
    end
    
    it "should be able to be called on a ThinkingSphinx::Search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      lambda {
        search.by_name('foo')
      }.should_not raise_error
    end
    
    it "should return the search object it gets called upon" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').should == search
    end
    
    it "should apply the scope options to the underlying search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').options[:conditions].should == {:name => 'foo'}
    end
    
    it "should combine hash option scopes such as :conditions" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').by_foo('bar').options[:conditions].
        should == {:name => 'foo', :foo => 'bar'}
    end
    
    it "should combine array option scopes such as :classes" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.with_betas.options[:classes].should == [Alpha, Beta]
    end
  end
end

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  before_filter :require_meta
  before_filter :set_active_tab
  def require_meta
    @hot_celebs = Tag.counts(:order => "count desc", :limit=>11, :start_at => 3.weeks.ago)
    @all_time_celebs = Tag.counts(:order=>"count desc", :limit=>11)
    @hot_topics = Topic.paginate(:all, :page => params[:page], :order => 'updated_at DESC', :per_page => 10)
    @all_time_topics
  end
  
  protected
  
  # # Borrowed from http://rpheath.com/posts/304-tabbed-navigation-in-rails-refactored
  def set_active_tab
    # will default to controller_name if @active_tab
    # has not been set by another controller
    @active_tab ||= self.controller_name.to_sym
  end
  
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end

class TopicsController < ApplicationController
  def index
    @topics = Topic.paginate(:all, :page => params[:page], :order => 'updated_at DESC', :per_page => 40)
  end

  def show
    @topic = Topic.find_by_id(params[:id])
    @title = @topic.focus
  end

end

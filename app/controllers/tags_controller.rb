class TagsController < ApplicationController
  def index
    #@tags = Tag.paginate(:all, :page => params[:page], :order => 'count DESC', :per_page => 20)
    @tags = Tag.counts(:order => "count desc")
  end

  def show
    @tag = Tag.find_by_permalink(params[:permalink])
  end

end

class PostsController < ApplicationController
  def index
    @posts = Post.paginate(:all, :page => params[:page], :order => 'created_at DESC', :per_page => 20)
  end

  def show
    @post = Post.find_by_permalink(params[:permalink])
  end

end

class PostsController < ApplicationController
  def index
    @posts = Post.paginate(:all, :page => params[:page], :order => 'created_at DESC', :per_page => 10)
  end

  def show
    @post = Post.find_by_permalink(params[:permalink])
    @title = @post.title
  end

end

class TopicsController < ApplicationController
  def index
    #@topics = Topic.paginate(:all, :page => params[:page], :order => 'updated_at DESC', :per_page => 10)
#=begin
    @topic_records = Topic.paginate(:all, :page => params[:page], :order => 'updated_at DESC', :per_page => 10)
    topics = []
    # reduce posts so that we don't have duplicates associated to multiple topics
    posts_in_use = {}
    @topic_records.each_with_index do|trec,i|
      # pull back posts ordered by time look at the top 5 matching
      posts = Post.latest_first.search(trec.query, :match_mode => :extended, :per_page => 5)
      use_posts = []
      posts.each_with_weighting do|post, weight|
        if posts_in_use[post.id]
          # the post has a higher weight for this topic then a previous topic
          if posts_in_use[post.id][:weight] < weight
            # reject from previous topic
            topics[posts_in_use[post.id][:idx]][:posts].reject!{|p| p.id == post.id}
            post.weight = weight
            # add to this topic
            use_posts << post
            # record the new weight and topic idx
            posts_in_use[post.id] = {:weight => weight, :idx => i}
          end
        else
          # never been seen before include it by default
          posts_in_use[post.id] = {:weight => weight, :idx => i}
          post.weight = weight
          use_posts << post
        end
      end
      topics << {:topic => trec, :posts => use_posts, :total_entries => posts.total_entries }
    end

    # make a final pass over all topics searching for duplicate posts
    posts_in_use = {}
    topics.each_with_index do|topic,i|
      topic[:posts].each do|post|
        if posts_in_use[post.id]
          if posts_in_use[post.id][:weight] < post.weight
            idx = posts_in_use[post.id][:idx]
            topics[idx][:posts].reject!{|p| p.id == post.id}
          end
        else
          # note it
          posts_in_use[post.id] = {:weight => post.weight, :idx => i}
        end
      end
    end
    @topics = topics.reject{|t| t[:posts].empty? }
#=end
  end

  def show
    @topic = Topic.find_by_id(params[:id])
    @title = @topic.focus
  end

end

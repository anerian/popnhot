class CleanUpPeopleBodyMigration < ActiveRecord::Migration
  def self.up
    require 'hpricot'
    feed = Feed.find_by_klass("People")
    if feed and feed.posts
      feed.posts.each do|p|
        doc = Hpricot(p.body)
        body = (doc/'div.articleBody')
        body = (doc/'body') unless p.body
        p.body = body.inner_html
        p.save! unless p.body.blank?
      end
    end
    feed = Feed.find_by_klass('Celebuzz')
    if feed and feed.posts
      feed.posts.each do|p|
        doc = Hpricot(p.body)
        body = doc.at('div.story-body')
        if body
          p.body = body.inner_html
          p.save! unless p.body.blank?
        end
      end
    end
  end

  def self.down
  end
end

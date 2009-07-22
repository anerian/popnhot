module TagsHelper
  def tag_class(tag)
    count = tag.count
    score = 0

    if count >= 4
      score = 4
    elsif count == 3
      score = 3
    elsif count == 2
      score = 2
    elsif count <= 1
      score = 1
    end

    taggings = tag.taggings(:order => :created_at).first
    range = (Time.now - (0.5).day.ago)
    placement = Time.now - taggings.created_at
    delta = range - placement

    if delta < (range*0.5) and score < 4
      score += 1
      #puts "Boost: #{tag.name}"
    elsif score > 0
      score -= 1
      #puts "Lower: #{tag.name}"
    end

    "tag#{score}"
  end
end

class Asset < ActiveRecord::Base
  belongs_to :posts
  has_attachment :storage     => :file_system,  
                 :thumbnails  => { :thumb => '120>', :tiny => [50, 50] },
                 :max_size    => 50.megabytes,
                 :path_prefix => 'public/content-files',
                 :processor   => 'Rmagick' #lock down to rmagick
  validates_as_attachment
  validate :rename_unique_filename
  
  validates_uniqueness_of :filename, 
                          :scope => [ :parent_id, :thumbnail ], 
                          :if => Proc.new {|f| f.rename.blank? }

  @@image_meta = %w(w h x y degrees scale)
 
  # overriding methods from attachment_fu to support custom filesnames
  def full_filename(thumbnail = nil)
    thumbnail = thumbnail.blank? ? self.thumbnail : thumbnail
    
    file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix].to_s
    
    File.join(Merb.root, file_system_path, *partitioned_path(thumbnail_name_for(thumbnail)))
  end
  
  def thumbnail_name_for(thumbnail = nil)
    return filename if thumbnail.blank?
    
    "#{thumbnail.to_s}/#{filename}"
  end
  
  # places assets in /content-files/:source/:checksum(filename)[0..1]/:filename
  def partitioned_path(args) 
    [ permalink, args ]
  end

  def resize_thumb(w = 240, h = 180)
    if width > w || height > h
      ratio = [(width.to_f/w.to_f), (height.to_f/h.to_f)].max
      
      w = (width / ratio)
      h = (height / ratio)
    else
      w = width; h = height
    end
    
    [w, h]
  end
  
protected

  def rename_unique_filename
    if (@rename == true) && ((@old_filename && !@old_filename.eql?(full_filename)) || new_record?) && errors.empty? && filename
      i = 1
      pieces = filename.split('.')
      ext = pieces.size == 1 ? nil : pieces.pop
      base = pieces * '.'
      
      while File.exists?(full_filename)
        write_attribute :filename, base + "_#{i}#{".#{ext}" if ext}"
        i += 1
      end
    end
  end
  
  def permalink
    date = created_at || Time.now.utc
    pieces = [ ::MD5.md5(filename).hexdigest[0..1], "#{date.year}-#{date.month}" ]
    pieces * '/'
  end
end

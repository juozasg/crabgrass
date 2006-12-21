class Avatar < FlexImage::Model
  # limit image size to 96 x 96
  pre_process_image :size => '96x96', :crop => true
  
  belongs_to :viewable, :polymorphic => true

  def self.pixels(size)
    case size
      when 'xsmall'; '16x16'
      when 'small' ; '32x32'
      when 'medium'; '48x48'
      when 'large' ; '64x64'
      when 'xlarge'; '96x96'
      else; nil
    end
  end
  
end

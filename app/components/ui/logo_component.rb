class Ui::LogoComponent < ViewComponent::Base
  def initialize(size: 'lg')
    @size = size
  end
  
  private
  
  attr_reader :size
  
  def logo_classes
    case @size
    when 'sm'
      'text-xl'
    when 'md'
      'text-2xl'
    when 'lg'
      'text-4xl'
    else
      'text-4xl'
    end
  end
end

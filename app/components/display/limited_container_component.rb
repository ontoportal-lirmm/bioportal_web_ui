class Display::LimitedContainerComponent < ViewComponent::Base
  renders_one :revealButton
  def initialize(max_height: '90')
    @max_height = max_height
  end
end

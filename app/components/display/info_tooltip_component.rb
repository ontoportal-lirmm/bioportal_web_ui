# frozen_string_literal: true

class Display::InfoTooltipComponent < ViewComponent::Base

  def initialize(text: )
    super
    @text = text
  end
  def call
    image_tag("icons/info.svg", data:{controller:'tooltip', 'tooltip-interactive-value': 'true'}, title: @text)
  end

end

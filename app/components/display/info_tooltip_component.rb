# frozen_string_literal: true

class Display::InfoTooltipComponent < ViewComponent::Base

  def initialize(text: )
    super
    @text = text
  end
  def call
    image_tag("summary/info.svg", data:{controller:'tooltip'}, title: @text)
  end

end

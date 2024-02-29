# frozen_string_literal: true

class Display::InfoTooltipComponent < ViewComponent::Base

  def initialize(text: nil , icon: "info.svg")
    super
    @text = text
    @icon = icon
  end
  def call
    inline_svg_tag "icons/#{@icon}", data:{controller:'tooltip', 'tooltip-interactive-value': 'true'}, title: @text
  end

end

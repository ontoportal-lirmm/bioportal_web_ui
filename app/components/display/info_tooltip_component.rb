# frozen_string_literal: true

class Display::InfoTooltipComponent < ViewComponent::Base

  def initialize(text: nil , icon: "info.svg")
    super
    @text = text
    @icon = icon
  end
  def call
    content_tag(:div, data:{controller:'tooltip', 'tooltip-interactive-value': 'true'}, title: @text, style: 'display: inline-block;') do
      if content
        content
      else
        inline_svg_tag "icons/#{@icon}", width: '20', height: '20'
      end
    end
  end

end

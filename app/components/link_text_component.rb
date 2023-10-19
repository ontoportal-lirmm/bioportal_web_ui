# frozen_string_literal: true

class LinkTextComponent < ViewComponent::Base

  def initialize(text:, icon: nil, target: nil)
    @text = text
    @icon = icon
    @target = target
  end

  def call
    svg_icon = !@icon&.empty? ? inline_svg(@icon) : ''
    "#{@text}<span class='mx-1'>#{svg_icon}<span>".html_safe
  end
end

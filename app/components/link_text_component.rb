# frozen_string_literal: true

class LinkTextComponent < ViewComponent::Base

  def initialize(text:, icon: nil)
    @text = text
    @icon = icon
  end

  def call
    svg_icon = !@icon&.empty? ? inline_svg(@icon) : ''
    "#{@text}<span class='mx-1'>#{svg_icon}<span>".html_safe
  end
end

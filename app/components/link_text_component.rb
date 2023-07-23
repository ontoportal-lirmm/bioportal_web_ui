# frozen_string_literal: true

class LinkTextComponent < ViewComponent::Base

  def initialize(text:, icon: 'open-popup')
    @text = text
    @icon = icon
  end

  def call
    "#{@text}<span class='mx-1'>#{inline_svg(@icon)}<span>".html_safe
  end
end

# frozen_string_literal: true

class LinkTextComponent < ViewComponent::Base

  def initialize(text:, icon: nil, target: nil)
    @text = text
    @icon = icon
    @target = target
  end

  def call
    svg_icon = !@icon&.empty? ? inline_svg(@icon) : ''
    extra_span = @text == t('mappings.upload_mappings') ? '' : "<span class='mx-1'>#{svg_icon}</span>"
    "#{@text}#{extra_span}".html_safe
  end  
end

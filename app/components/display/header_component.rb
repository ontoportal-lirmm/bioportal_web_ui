# frozen_string_literal: true

class Display::HeaderComponent < ViewComponent::Base

  renders_one :text

  def initialize(text: nil, tooltip: nil)
    super
    @text = text
    @info = tooltip
  end

  def call
    content_tag(:div, class: 'header-component') do
      out = content_tag(:p, text || @text)
      if @info && !@info.empty?
        out = out + render(Display::InfoTooltipComponent.new(text: @info))
      end
      out
    end
  end

end

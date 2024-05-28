# frozen_string_literal: true

class Display::HeaderComponentPreview < ViewComponent::Preview

  # @param text text
  # @param tooltip text
  def default(text: 'header text' , tooltip: 'text tooltip')
    render Display::HeaderComponent.new(text: text, tooltip: tooltip)
  end
end

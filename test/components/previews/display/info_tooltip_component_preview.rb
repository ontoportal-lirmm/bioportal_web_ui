# frozen_string_literal: true

class Display::InfoTooltipComponentPreview < ViewComponent::Preview

  # @param text text
  def default(text: 'tooltip text')
    render Display::InfoTooltipComponent.new(text: text)
  end
end

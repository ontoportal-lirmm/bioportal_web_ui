# frozen_string_literal: true

class Display::InfoTooltipComponentPreview < ViewComponent::Preview
  def default
    render(Display::InfoTooltipComponent.new)
  end
end

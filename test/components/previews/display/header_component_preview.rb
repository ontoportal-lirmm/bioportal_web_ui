# frozen_string_literal: true

class Display::HeaderComponentPreview < ViewComponent::Preview
  def default
    render(Display::HeaderComponent.new)
  end
end

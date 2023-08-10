# frozen_string_literal: true

class Display::ImageComponentPreview < ViewComponent::Preview
  def default
    render(Display::ImageComponent.new)
  end
end

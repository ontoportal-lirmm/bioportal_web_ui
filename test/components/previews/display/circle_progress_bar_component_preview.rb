# frozen_string_literal: true

class Display::CircleProgressBarComponentPreview < ViewComponent::Preview

  # @param count number
  # @param max number
  def default(count: 63, max: 100)
    render CircleProgressBarComponent.new(count: count, max: max)
  end
end

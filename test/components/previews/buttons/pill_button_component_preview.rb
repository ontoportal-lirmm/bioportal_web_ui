# frozen_string_literal: true

class Buttons::PillButtonComponentPreview < ViewComponent::Preview
  # @param text text
  def default(text: 'Watch')
    render PillButtonComponent.new(text: text)
  end
end

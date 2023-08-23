# frozen_string_literal: true

class Buttons::PillButtonComponentPreview < ViewComponent::Preview
  # @param text text
  def default(text: 'hello')
    render PillButtonComponent.new(text: text)
  end
end

# frozen_string_literal: true

class Layout::CardComponentPreview < ViewComponent::Preview
  # @param text textarea
  def default(text: 'text here')
    render Layout::CardComponent.new do
      text.html_safe
    end
  end
end

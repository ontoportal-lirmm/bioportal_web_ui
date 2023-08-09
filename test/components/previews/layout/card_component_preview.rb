# frozen_string_literal: true

class Layout::CardComponentPreview < ViewComponent::Preview
  def default
    render(Layout::CardComponent.new)
  end
end

# frozen_string_literal: true

class Layout::HorizontalListComponentPreview < ViewComponent::Preview
  def default
    render(Layout::HorizontalListComponent.new)
  end
end

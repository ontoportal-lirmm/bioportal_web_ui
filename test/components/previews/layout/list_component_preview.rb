# frozen_string_literal: true

class Layout::ListComponentPreview < ViewComponent::Preview
  def default
    render(Layout::ListComponent.new)
  end
end

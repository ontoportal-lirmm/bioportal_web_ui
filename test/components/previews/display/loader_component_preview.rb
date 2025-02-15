# frozen_string_literal: true

class LoaderComponentPreview < ViewComponent::Preview
  def default
    render LoaderComponent.new
  end

  def small
    render LoaderComponent.new(small: true)
  end

end

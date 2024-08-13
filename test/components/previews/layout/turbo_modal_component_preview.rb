# frozen_string_literal: true

class Layout::TurboModalComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'

  include ActionView::Helpers::TagHelper
  include ActionView::Context

  # @param title text
  # @param message text
  def default(message: 'hello you !', title: 'title')
    render TurboModalComponent.new(title: title, show: true) do
      content_tag(:div, message, class: 'p-5')
    end
  end
end

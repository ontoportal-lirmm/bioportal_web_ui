# frozen_string_literal: true

class Display::FieldContainerComponentPreview < ViewComponent::Preview

  # @param label text
  # @param value text
  #
  def default(label: 'label' , value: 'value')
    render FieldContainerComponent.new(label: label , value: value)
  end
end

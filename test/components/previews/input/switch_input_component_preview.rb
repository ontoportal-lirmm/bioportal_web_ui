# frozen_string_literal: true

class Input::SwitchInputComponentPreview < ViewComponent::Preview

  # @param label text
  def default(label: 'Label')
    render SwitchInputComponent.new(id: 'id', name: 'selected_metadata[]', value: '', label: label)
  end
end

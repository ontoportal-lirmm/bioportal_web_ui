# frozen_string_literal: true

class Input::SelectComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'

  def default(id: "", name: "", values: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: false, open_to_add_values: false)
    render Input::SelectComponent.new(id: id, name: name, value: values, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end

  def multiple(id: "", name: "", values: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: true, open_to_add_values: false)
    render Input::SelectComponent.new(id: id, name: name, value: values, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end

  def open_to_add(id: "", name: "", values: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: true , open_to_add_values: true)
    render Input::SelectComponent.new(id: id, name: name, value: values, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end
end

# frozen_string_literal: true

class Form::SelectComponentPreview < ViewComponent::Preview
  def default(id: "", name: "", value: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: false, open_to_add_values: false)
    render Form::SelectComponent.new(id: id, name: name, value: value, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end

  def multiple(id: "", name: "", value: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: true, open_to_add_values: false)
    render Form::SelectComponent.new(id: id, name: name, value: value, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end

  def open_to_add(id: "", name: "", value: ["choices 1", "choices 2", "choices 3"], selected: "choices 2", multiple: true , open_to_add_values: true)
    render Form::SelectComponent.new(id: id, name: name, value: value, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end
end

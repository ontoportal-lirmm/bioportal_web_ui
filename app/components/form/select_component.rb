# frozen_string_literal: true

class Form::SelectComponent < SelectInputComponent

  def initialize(id:, name:, values:, selected:, multiple: false, open_to_add_values: false)
    super(id: id, name: name, values: values, selected: selected, multiple: multiple, open_to_add_values: open_to_add_values)
  end
end

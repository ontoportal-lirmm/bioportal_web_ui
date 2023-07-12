# frozen_string_literal: true

class Form::SelectComponent < InputFieldComponent

  def initialize(id: nil, label: '', name:, value: [], selected: '', placeholder: '', error_message: '', helper_text: '', multiple: false, open_to_add_values: false)
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text)
    @values = value
    @selected = selected
    @open_to_add_values = open_to_add_values
    @multiple = multiple
    @id = id
  end
end

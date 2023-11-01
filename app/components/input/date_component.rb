# frozen_string_literal: true

class Input::DateComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: Date.today, placeholder: '', error_message: '', helper_text: '', id: nil, max_date: nil)
    data_flat_picker = { controller: "flatpickr", flatpickr_date_format: "Y-m-d", flatpickr_alt_input: "true", flatpickr_alt_format: "F j, Y"}
    data_flat_picker[:flatpickr_max_date] = max_date if max_date

    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text, data: data_flat_picker, id: id)
  end

  def call
    render Input::InputFieldComponent.new(label: @label, name: @name, value: @value,  placeholder: @placeholder, error_message: @error_message, helper_text: @helper_text, data: @data, type: 'date', id: @id)
  end
end

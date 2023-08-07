# frozen_string_literal: true

class Input::DateComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: Date.today, placeholder: '', error_message: '', helper_text: '')
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end

  def call
    render Input::InputFieldComponent.new(label: @label, name: @name, value: @value,  placeholder: @placeholder, error_message: @error_message, helper_text: @helper_text, type: 'date')
  end
end

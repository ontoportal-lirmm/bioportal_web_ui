# frozen_string_literal: true

class Input::TextInputComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: nil, placeholder: '', error_message: '', helper_text: '', disabled: false)
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text, disabled: disabled)
  end

  def call
    render Input::InputFieldComponent.new(label: @label, name: @name, value: @value,  placeholder: @placeholder,
                                          error_message: @error_message, helper_text: @helper_text,
                                          type: @type, disabled: @disabled)
  end
end

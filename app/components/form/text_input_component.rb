# frozen_string_literal: true

class Form::TextInputComponent < InputFieldComponent
  def initialize(label: '', name:, value: nil, placeholder: '', error_message: '', helper_text: '', type: 'text')
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text, type: type)
  end
end

# frozen_string_literal: true

class Form::DateComponent < InputFieldComponent
  def initialize(label: '', name:, value: Date.today, placeholder: '', error_message: '', helper_text: '')
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end
end

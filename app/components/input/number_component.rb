# frozen_string_literal: true

class Input::NumberComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: nil, placeholder: '', error_message: '', helper_text: '', min: '', max: '', step: '')
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text)
    @min = min
    @max = max
    @step = step
  end

  def call
    render Input::InputFieldComponent.new(label: @label, name: @name, value: @value,  placeholder: @placeholder, error_message: @error_message, helper_text: @helper_text, type: "number", min: @min, max: @max, step: @step)
  end
end

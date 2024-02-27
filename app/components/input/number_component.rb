# frozen_string_literal: true

class Input::NumberComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: nil, placeholder: '', error_message: '', helper_text: '', min: '', max: '', step: '', tooltip: nil)
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text, tooltip: tooltip)
    @min = min
    @max = max
    @step = step
  end

  def call
    render Input::InputFieldComponent.new(label: @label, name: @name, value: @value,  placeholder: @placeholder, error_message: @error_message, helper_text: @helper_text, tooltip: @tooltip ,type: "number", min: @min, max: @max, step: @step)
  end
end

# frozen_string_literal: true

class Form::TextAreaComponentPreview < ViewComponent::Preview
  # This is a textarea field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To give it a hint (placeholder): define the param hint with the hind you want to be displayed.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.

  # @param label text
  # @param placeholder text
  # @param error_message text
  # @param helper_text text
  # @param rows number

  def default(label: "Label", placeholder: "", error_message: "", helper_text: "", rows: 5)
    render Form::TextAreaComponent.new(label: label, name: "name",value: '', placeholder: placeholder, error_message: error_message, helper_text: helper_text, rows: rows)
  end
end

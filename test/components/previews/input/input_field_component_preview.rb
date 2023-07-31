# frozen_string_literal: true

class Input::InputFieldComponentPreview < ViewComponent::Preview

  # This is a date input field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
  # @param label text
  # @param error_message text
  # @param helper_text text

  def date(label: "Label", placeholder: "", error_message: "", helper_text: "")
    render Input::DateComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end


  # This is a url input field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
  # @param label text
  # @param error_message text
  # @param helper_text text

  def email(label: "Label", placeholder: "", error_message: "", helper_text: "")
    render Input::EmailComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end


  def file
    render Input::FileInputComponent.new(name: "file")
  end


  # This is a url input field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
  # @param label text
  # @param error_message text
  # @param helper_text text

  def password(label: "Label", placeholder: "", error_message: "", helper_text: "")
    render Input::PasswordComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end


  # This is a url input field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
  # @param label text
  # @param error_message text
  # @param helper_text text

  def url(label: "Label", placeholder: "", error_message: "", helper_text: "")
    render Input::UrlComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end

  # This is a text input field:
  # - To use it without a label: don't give a value to the param label or leave it empty.
  # - To give it a hint (placeholder): define the param hint with the hind you want to be displayed.
  # - To put it in error state: define the param error_message with the error message you want to be displayed.
  # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
  # @param label text
  # @param placeholder text
  # @param error_message text
  # @param helper_text text

  def text(label: "Label", placeholder: "", error_message: "", helper_text: "")
    render Input::TextInputComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
  end

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

  def text_area(label: "Label", placeholder: "", error_message: "", helper_text: "", rows: 5)
    render Input::TextAreaComponent.new(label: label, name: "name",value: '', placeholder: placeholder, error_message: error_message, helper_text: helper_text, rows: rows)
  end
end

# frozen_string_literal: true

class Input::PasswordComponentPreview < ViewComponent::Preview
  def default
    # This is a url input field:
    # - To use it without a label: don't give a value to the param label or leave it empty.
    # - To put it in error state: define the param error_message with the error message you want to be displayed.
    # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
    # @param label text
    # @param error_message text
    # @param helper_text text

    def default(label: "Label", placeholder: "", error_message: "", helper_text: "")
      render Input::PasswordComponent.new(label: label, name: "name", placeholder: placeholder, error_message: error_message, helper_text: helper_text)
    end
  end
end

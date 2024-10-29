# frozen_string_literal: true

class Input::TextAreaComponent < Input::InputFieldComponent
  def initialize(label: '', name:, value: nil, placeholder: '', error_message: '', helper_text: '', rows: "5", resize: nil)
    super(label: label, name: name, value: value,  placeholder: placeholder, error_message: error_message, helper_text: helper_text)
    @rows = rows
    @resize = resize
  end
  def resize
    @resize ? "resize: vertical;" : ""
  end
end

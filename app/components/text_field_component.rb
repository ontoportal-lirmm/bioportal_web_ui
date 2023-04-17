# frozen_string_literal: true

class TextFieldComponent < FormGroupComponent

  def initialize(object:, name: nil, method:, label: nil, required: false, inline: true)
    super
    @object = object
  end
end

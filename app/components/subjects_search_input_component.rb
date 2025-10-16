# frozen_string_literal: true

class SubjectsSearchInputComponent < ViewComponent::Base

  def initialize(attr:, attr_key:, values: [], label: nil, attr_header_label: nil, error_message: nil)
    @attr = attr
    @attr_key = attr_key
    @values = values
    @label = label
  end
end

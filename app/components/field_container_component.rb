# frozen_string_literal: true

class FieldContainerComponent < ViewComponent::Base

  def initialize(label:, value:)
    super
    @label = label
    @value = value
  end
end

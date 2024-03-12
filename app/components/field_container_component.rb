# frozen_string_literal: true

class FieldContainerComponent < ViewComponent::Base

  renders_one :label
  def initialize(label: nil, value: nil, truncate: false)
    super
    @label = label
    @value = value
  end

  def show?
    content && !content.strip.empty? || (!@value.nil? && !@value.strip.empty?)
  end
end

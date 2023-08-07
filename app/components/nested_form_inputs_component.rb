# frozen_string_literal: true

class NestedFormInputsComponent < ViewComponent::Base

  renders_one :template
  renders_one :header
  renders_many :rows
  renders_one :empty_state

  def initialize(object_name: '')
    super
    @object_name = object_name
  end
end

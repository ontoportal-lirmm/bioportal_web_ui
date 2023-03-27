# frozen_string_literal: true

class NestedFormInputsComponent < ViewComponent::Base

  renders_one :template
  renders_many :rows
end

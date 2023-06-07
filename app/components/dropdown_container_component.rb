# frozen_string_literal: true

class DropdownContainerComponent < ViewComponent::Base

  def initialize(title:, properties:)
    super
    @title = title
    @properties = properties
  end
end

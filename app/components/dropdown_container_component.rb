# frozen_string_literal: true

class DropdownContainerComponent < ViewComponent::Base
  renders_one :empty_state
  def initialize(title:, id:, tooltip:nil)
    super
    @title = title
    @id = id
  end
end

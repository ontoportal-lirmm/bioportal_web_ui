# frozen_string_literal: true

class DropdownContainerComponent < ViewComponent::Base

  def initialize(title:, id:)
    super
    @title = title
    @id = id
  end
end

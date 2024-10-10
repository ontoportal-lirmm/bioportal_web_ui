# frozen_string_literal: true

class DropdownContainerComponent < ViewComponent::Base
  renders_one :empty_state
  def initialize(title:, id:, tooltip:nil, is_open: false)
    super
    @title = title
    @id = id
    @tooltip = tooltip
    @is_open = is_open
  end
  def open_class
    @is_open ? "show" : ""
  end
end

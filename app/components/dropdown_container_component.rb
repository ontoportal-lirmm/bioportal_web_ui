# frozen_string_literal: true

class DropdownContainerComponent < ViewComponent::Base
  include ApplicationHelper
  def initialize(title:, id:, tooltip:nil)
    super
    @title = title
    @id = id
    @tooltip = tooltip
  end
end

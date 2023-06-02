# frozen_string_literal: true

class DropdownSectionButtonComponent < ViewComponent::Base

  renders_one :header
  renders_many :items

  def initialize(divide: true)
    super
    @divide = divide
  end

  def show_divider?
    @divide
  end
end

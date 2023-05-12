# frozen_string_literal: true

class ToggleInputComponent < ViewComponent::Base

  def initialize(first_option: [], second_option: [])
    super
    @options = [first_option, second_option] # An array of [id, name, label]
  end

  def option_id(order)
    @options[order][0]
  end

end

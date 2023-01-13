# frozen_string_literal: true

class SwitchInputComponent < ViewComponent::Base


  def initialize(id:, name: , label: nil, value: '', checked: false)
    super
    @id = id
    @name = name
    @label = label
    @value = value.nil? || value.empty? ? @name : value
    @checked = checked
  end
end

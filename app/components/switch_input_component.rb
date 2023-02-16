# frozen_string_literal: true

class SwitchInputComponent < ViewComponent::Base


  def initialize(id:, name: , label: nil, value: '', checked: false, boolean_switch: false)
    super
    @id = id
    @name = name
    @label = label
    @value = value.nil? || value.empty? ? @name : value
    @checked = checked
    @boolean_switch = boolean_switch
  end

  def boolean_switch_action
    "this.previousElementSibling.value = this.previousElementSibling.value !== 'true'" if @boolean_switch
  end

  def check_box_name
    @name unless @boolean_switch
  end

  def check_box_id
    @boolean_switch ? @id +"_checkbox" :@id
  end
end

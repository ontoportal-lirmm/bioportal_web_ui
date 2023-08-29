# frozen_string_literal: true

class SelectInputComponent < ViewComponent::Base

  def initialize(id:, name:, values:, selected:, multiple: false, open_to_add_values: false, data: {})
    super
    @id = id || ""
    @name = name
    @values = values
    @selected = selected
    @multiple = multiple
    @open_to_add_values = open_to_add_values
    @data = data
  end
  
  def call 
    select_input_tag(@name, @values, @selected, multiple: @multiple, open_to_add_values: @open_to_add_values)
  end

  private

  def select_input_tag(id, values, selected, options = {})
    multiple = options[:multiple] || false
    open_to_add_values = options[:open_to_add_values] || false
    data = @data.merge({
                         'select-input-multiple-value': multiple,
                         'select-input-open-add-value': open_to_add_values
                       })
    data[:controller] = "#{data[:controller]} select-input"
    select_html_options = {
      id: "select_#{id}",
      autocomplete: "off",
      multiple: multiple,
      data: data
    }




    select_tag(id, options_for_select(values, selected), select_html_options)
  end
end

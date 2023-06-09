# frozen_string_literal: true

class SelectInputComponent < ViewComponent::Base

  def initialize(id:, name:, values:, selected:, multiple: false, hide: false)
    super
    @id = id
    @name = name
    @values = values
    @selected = selected
    @multiple = multiple
    @hide = hide
  end

  def options_values
    if @selected.nil? || @selected.empty?
      @selected = 0
      @values.unshift('')
    end
    options_for_select(@values, @selected)
  end
end

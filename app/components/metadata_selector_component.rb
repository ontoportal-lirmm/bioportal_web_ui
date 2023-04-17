# frozen_string_literal: true

class MetadataSelectorComponent < ViewComponent::Base

  include ActionView::Helpers::FormOptionsHelper

  def initialize(label: 'Select properties', selected:, values:, inline: false, multiple: true)
    super
    @label = label
    @selected_values = selected
    @metadata_data = values
    @inline = inline
    @multiple = multiple
  end

  def options_data
    options_for_select(@metadata_data, selected: @selected_values)
  end
end

# frozen_string_literal: true

class Layout::RevealComponent < ViewComponent::Base
  renders_one :button
  renders_many :containers

  def initialize(selected: nil, possible_values: [], hidden_class: 'd-none', toggle: false)
    @hidden_class = hidden_class
    @possible_values = toggle && possible_values.empty? ? [true] : possible_values
    @selected = selected
    @toggle = toggle
  end

  def container_data
    {
      controller: 'reveal-component',
      'reveal-component-hidden-class': @hidden_class
    }
  end
end

# frozen_string_literal: true

class Layout::RevealComponent < ViewComponent::Base
  renders_one :button

  def initialize(init_show: false, show_condition: nil,hidden_class: 'd-none')
    @hidden_class = hidden_class
    @init_show = init_show
    @show_condition = show_condition
  end

  def container_data
    out = {
      controller: 'reveal-component',
      'reveal-component-hidden-class': @hidden_class
    }
    out['reveal-component-condition-value'] = @show_condition if @show_condition
    out
  end
end

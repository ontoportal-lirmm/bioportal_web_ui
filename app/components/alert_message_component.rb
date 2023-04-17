# frozen_string_literal: true

class AlertMessageComponent < ViewComponent::Base
  include Turbo::FramesHelper
  def initialize(id: '', type: 'info')
    @id = id
    @type = "alert-#{type}"
  end
end

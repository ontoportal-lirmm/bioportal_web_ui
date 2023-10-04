# frozen_string_literal: true

class AlertMessageComponent < ViewComponent::Base
  include Turbo::FramesHelper
  def initialize(id: '', message: nil, type: 'info', closeable: true)
    @id = id
    @type = "alert-#{type}"
  end
end

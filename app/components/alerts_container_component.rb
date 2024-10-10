# frozen_string_literal: true

class AlertsContainerComponent < ViewComponent::Base
  include Turbo::FramesHelper
  def initialize(id:)
    @id = id
  end

end

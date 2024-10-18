# frozen_string_literal: true

class FederatedPortalButtonComponent < ViewComponent::Base
  attr_reader :name, :tooltip, :link, :color, :light_color

  def initialize(name:, link:, color:, tooltip:, light_color:)
    @name = name
    @tooltip = tooltip
    @link = link
    @color = color
    @light_color = light_color
  end
end

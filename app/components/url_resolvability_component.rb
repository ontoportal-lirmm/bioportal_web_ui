# frozen_string_literal: true

class UrlResolvabilityComponent < ViewComponent::Base

  include OntologiesHelper

  def initialize(resolvable: false, supported_formats: [], status: nil)
    @resolvable = resolvable
    @supported_formats = supported_formats
    @status = status
  end

  def call
    if @resolvable && @supported_formats.size > 1
      render Display::InfoTooltipComponent.new(text: "The URL is resolvable and support the following formats: #{@supported_formats.join(', ')}", icon: status_icons(ok: true))
    elsif @resolvable
      render Display::InfoTooltipComponent.new(text: "The URL resolvable but not content negotiable, support only: #{@supported_formats.join(', ')}", icon: status_icons(warning: true))
    else
      render Display::InfoTooltipComponent.new(text: "The URL is not resolvable and not content negotiable (returns #{@status})", icon: status_icons(error: true))
    end
  end
end

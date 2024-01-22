# frozen_string_literal: true

class UrlResolvabilityComponent < ViewComponent::Base

  include OntologiesHelper, CheckResolvabilityHelper

  def initialize(resolvable: false, supported_formats: [], status: nil)
    @resolvable = resolvable
    @supported_formats = supported_formats
    @status = status
  end

  def call
    text = check_resolvability_message(@resolvable, @supported_formats, @status)
    if @resolvable && @supported_formats.size > 1
      icon = status_icons(ok: true)
    elsif @resolvable
      icon = status_icons(warning: true)
    else
      icon = status_icons(error: true)
    end
    render Display::InfoTooltipComponent.new(text: text, icon: icon)
  end
end

# frozen_string_literal: true

class LinkFieldComponent < ViewComponent::Base

  def initialize(value:)
    super
    @value = value
  end


  def internal_link?
    @value.to_s.include?(URI.parse($REST_URL).hostname) || @value.to_s.include?($UI_HOSTNAME)
  end

end

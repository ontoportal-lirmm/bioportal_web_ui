# frozen_string_literal: true

class LinkFieldComponent < ViewComponent::Base

  def initialize(value:, raw: false)
    super
    @value = value
    @raw = raw
  end


  def internal_link?
    @value.to_s.include?(URI.parse($REST_URL).hostname) || @value.to_s.include?(URI.parse($UI_URL).hostname)
  end

end

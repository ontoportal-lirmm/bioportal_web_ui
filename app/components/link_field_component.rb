# frozen_string_literal: true

class LinkFieldComponent < ViewComponent::Base

  include ApplicationHelper, Turbo::FramesHelper

  def initialize(value:, raw: false, check_resolvability: false)
    super
    @value = value
    @raw = raw
    @check_resolvability = check_resolvability
  end

  def internal_link?
    @value.to_s.include?(URI.parse($REST_URL).hostname) || @value.to_s.include?(URI.parse($UI_URL).hostname)
  end

  def link_tag
    if internal_link?
      url = @raw ? @value : @value.to_s.split("/").last
      text = @raw ? @value : @value.to_s.sub("data.", "")
      target = ""
    else
      url = @value.to_s
      text = url
      target = "_blank"
    end

    if @check_resolvability
      link_to(text, url, target: target) + content_tag(:span, check_resolvability_container(url), style: 'display: inline-block;')
    else
      link_to(text, url, target: target)
    end

  end
end

# frozen_string_literal: true

class LinkFieldComponent < ViewComponent::Base

  include ApplicationHelper, Turbo::FramesHelper, ComponentsHelper

  def initialize(value:, raw: false, check_resolvability: false, enable_copy: true)
    super
    @value = value
    @raw = raw
    @check_resolvability = check_resolvability
    @enable_copy = enable_copy
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

    tag = link_to(text, url, target: target, class: 'text-truncate', style: "max-width: 330px; display: inline-flex;")
    link_to_with_actions(tag, url: url, copy: @enable_copy, check_resolvability: @check_resolvability)
  end

end

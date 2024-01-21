# frozen_string_literal: true

class LinkFieldComponent < ViewComponent::Base

  include ApplicationHelper, Turbo::FramesHelper

  def initialize(value:, raw: false, check_resolvability: false, enable_copy: false)
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

    tag = link_to(text, url, target: target)

    tag = tag + copy_link_to_clipboard(url) if @enable_copy

    tag = tag + resolvability_check_tag(url) if @check_resolvability
    
    tag
  end

  private

  def resolvability_check_tag(url)
    content_tag(:span, check_resolvability_container(url), style: 'display: inline-block;')
  end

  def copy_link_to_clipboard(url)
    content_tag(:span, style: 'display: inline-block;') do
      render ClipboardComponent.new(message: url)
    end
  end
end

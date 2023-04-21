require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'

module HomeHelper

  def render_footer_link(options = {})

    link_content = options[:text].presence
    link_content ||= image_tag(options[:img_src]) if options[:img_src].present?
    link_content ||= content_tag(:i, '', class: options[:icon]) if options[:icon].present?

    unless link_content.blank?
      link_to(link_content, options[:url], target: options[:target], class: options[:css_class].to_s, style: options[:text].blank? ? 'text-decoration: none' : '')
    end.to_s.html_safe

  end
end
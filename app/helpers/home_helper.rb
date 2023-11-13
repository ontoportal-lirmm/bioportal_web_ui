require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'

module HomeHelper

  def render_footer_link(options = {})
    link_content = options[:text][I18n.locale] || options[:text][:en] if options[:text]
    link_content ||= image_tag(options[:img_src]) if options[:img_src]
    link_content ||= content_tag(:i, '', class: options[:icon]) if options[:icon]
  
    link_to(link_content, options[:url], target: options[:target], class: options[:css_class].to_s, style: options[:text].blank? ? 'text-decoration: none' : '').html_safe if link_content
  end


  def format_number_abbreviated(number)
    if number >= 1_000_000
      (number / 1_000_000).to_s + 'M'
    elsif number >= 1_000
      (number / 1_000).to_s + 'K'
    else
      number.to_s
    end
  end  

end
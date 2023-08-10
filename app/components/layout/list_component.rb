# frozen_string_literal: true

class Layout::ListComponent < ViewComponent::Base

  renders_many :rows

  def call
    return if rows.map(&:to_s).reject(&:empty?).empty?

    content_tag(:div, style: 'padding: 0px 20px 20px 20px;') do
      out = ""
      rows.each do |row|
        next if row.nil? || row.to_s.empty?
        out = out + content_tag(:div, row.to_s, class: 'mb-1')
      end
      out.html_safe
    end
  end

end

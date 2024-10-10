# frozen_string_literal: true

class Layout::CardComponent < ViewComponent::Base
  renders_one :header, Display::HeaderComponent

  def call
    content_tag(:div, class: 'summary-card') do
      out = ''
      out = header  if header?
      raw(out.to_s + content)
    end
  end
end

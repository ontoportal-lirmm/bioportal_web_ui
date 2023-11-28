# frozen_string_literal: true

class Layout::HorizontalListComponent < ViewComponent::Base
  renders_many :elements

  def call
    return if elements.empty?

    content_tag(:div, class: 'd-flex flex-wrap align-items-center') do
      out = ''
      elements.each do |element|
        out = out +  content_tag(:div, element, class: 'mr-1 mb-1 text-truncate-scroll')
      end
      raw out
    end
  end

end

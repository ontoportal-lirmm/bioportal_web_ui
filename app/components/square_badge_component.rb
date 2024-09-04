# frozen_string_literal: true

class SquareBadgeComponent < ViewComponent::Base

  def initialize(label: , count: ,link: nil, color: nil)
    @label = label
    @count = count
    @link = link
    @color = color
  end

  def call
    return  if @count.to_i.zero?

    link_to(@link, class: 'browse-onology-card', 'data-turbo' => 'false', style: @color ? "color: #{@color} !important; border-color: #{@color}" : "") do
      concat(content_tag(:p, @count, class: 'browse-card-number'))
      concat(content_tag(:p, @label, class: 'browse-card-text'))
    end
  end

end

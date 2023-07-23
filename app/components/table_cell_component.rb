# frozen_string_literal: true

class TableCellComponent < ViewComponent::Base

  def initialize(width: nil, type: 'td')
    super
    @width = width
    @type = type
  end

  def call
    options = {}
    options[:width] = @width if @width
    content_tag(@type, content&.html_safe, options)
  end
end

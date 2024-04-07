# frozen_string_literal: true

class Display::RdfHighlighterComponent < ViewComponent::Base

  def initialize(format: , text: )
    @format = format
    @content = text
  end
end

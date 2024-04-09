# frozen_string_literal: true

class ClipboardComponent < ViewComponent::Base

  def initialize(icon, title: nil, message: nil, show_content: true)
    @icon = icon
    @title = title
    @message = message
    @show_content = show_content
  end
end

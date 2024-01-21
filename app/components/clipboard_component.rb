# frozen_string_literal: true

class ClipboardComponent < ViewComponent::Base

  def initialize(message: nil, show_content: true)
    @message = message
    @show_content = show_content
  end
end

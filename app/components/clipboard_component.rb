# frozen_string_literal: true

class ClipboardComponent < ViewComponent::Base

  def initialize(message: nil)
    @message = message
  end
end

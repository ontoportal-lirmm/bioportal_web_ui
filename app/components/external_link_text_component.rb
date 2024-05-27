# frozen_string_literal: true

class ExternalLinkTextComponent < LinkTextComponent

  def initialize(text:)
    super(text: text, icon: 'icons/external-link.svg')
  end
end

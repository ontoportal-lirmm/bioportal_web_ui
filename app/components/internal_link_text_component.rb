# frozen_string_literal: true

class InternalLinkTextComponent < LinkTextComponent
  def initialize(text:)
    super(text: text, icon: 'icons/internal-link.svg')
  end
end

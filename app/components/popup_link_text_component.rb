# frozen_string_literal: true

class PopupLinkTextComponent < LinkTextComponent

  def initialize(text:)
    super(text: text, icon: 'icons/popup-link.svg')
  end

end

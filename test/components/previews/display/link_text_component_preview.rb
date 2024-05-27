# frozen_string_literal: true

class Display::LinkTextComponentPreview < ViewComponent::Preview

  # @param text text
  # @param icon text
  def default(text: 'link text', icon: '')
    render ChipButtonComponent.new(text: LinkTextComponent.new(text: text, icon: icon).call, type: 'clickable')
  end

  # @param text text
  def internal(text: 'redirect inside  the site')
    render ChipButtonComponent.new(text: InternalLinkTextComponent.new(text: text).call, type: 'clickable')
  end

  # @param text text
  def external(text: 'go out of the site')
    render ChipButtonComponent.new(text: ExternalLinkTextComponent.new(text: text).call, type: 'clickable')
  end

  # @param text text
  def popup(text: 'open popup')
    render ChipButtonComponent.new(text: PopupLinkTextComponent.new(text: text).call, type: 'clickable')
  end
end

class Display::LanguageFieldComponentPreview < ViewComponent::Preview

  # @param value text
  def default(value: 'fr')
    render LanguageFieldComponent.new(value: value)
  end

end
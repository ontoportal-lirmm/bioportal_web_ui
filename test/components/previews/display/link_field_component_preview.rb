class Display::LinkFieldComponentPreview < ViewComponent::Preview

  # @param text text
  def default(text: "https://agroportal.lirmm.fr/")
    render LinkFieldComponent.new(value: text)
  end

end
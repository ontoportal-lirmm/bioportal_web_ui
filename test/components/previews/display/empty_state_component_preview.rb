class Display::EmptyStateComponentPreview < ViewComponent::Preview

  def default()
    render Display::EmptyStateComponent.new(text: 'No result was found')
  end
end

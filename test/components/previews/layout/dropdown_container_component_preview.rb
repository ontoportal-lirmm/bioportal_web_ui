# frozen_string_literal: true

class Layout::DropdownContainerComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'

  # @param title text
  # @param content textarea

  def default(title: 'title', content: 'content')
    render DropdownContainerComponent.new(id: 'id' , title: title) do
      content.html_safe
    end
  end
  
end

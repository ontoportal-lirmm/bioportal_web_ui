class Layout::PageHeaderComponentPreview < ViewComponent::Preview
    layout 'component_preview_not_centred'
    def default(title: 'title', description: 'here is the description' )
      render PageHeaderComponent.new(title: title , description: description) do
      end
    end
  end
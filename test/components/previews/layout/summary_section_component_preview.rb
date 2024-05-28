class Layout::SummarySectionComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'
  # @param title text
  # @param content textarea
  # @param link url
  # @param link_title  text
  # @param show_card  toggle
  def default(title: 'title' , link: nil, link_title: nil, show_card:  true, content: 'here is the content')
    render SummarySectionComponent.new(title: title , link: link, link_title: link_title, show_card:  show_card) do
         content.html_safe
    end
  end

end
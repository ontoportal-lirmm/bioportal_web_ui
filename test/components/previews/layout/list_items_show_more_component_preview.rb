class Layout::ListItemsShowMoreComponentPreview < ViewComponent::Preview

  def default
    render ListItemsShowMoreComponent.new do |component|
      10.times do |i|
        component.container do
          render ChipButtonComponent.new(
            url: "#",
            text: "Element #{i + 1}",
            type: "clickable"
          )
        end
      end
    end
  end

end

class Buttons::IconWithTooltipComponentPreview < ViewComponent::Preview

  # @param title text

  def edit(icon: "edit.svg", title: "Edit")
    render IconWithTooltipComponent.new(icon: icon, link: "#", title: title)
  end

  # @param title text

  def delete(icon: "icons/delete.svg", title: "Delete")
    render IconWithTooltipComponent.new(icon: icon, link: "#", title: title)
  end


  # @param title text

  def preview(icon: "eye.svg", title: "Preview")
    render IconWithTooltipComponent.new(icon: icon, link: "#", title: title)
  end


end

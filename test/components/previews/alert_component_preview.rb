class AlertComponentPreview < ViewComponent::Preview

  # @param message text
  # @param type select [primary, danger, success, info, light]

  def default(type: "success", message: "Here we can type a success or failure message to the user")
    render AlertMessageComponent.new(id: '', type: type) do
      message
    end
  end

end
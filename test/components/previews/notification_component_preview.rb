class NotificationComponentPreview < ViewComponent::Preview

  # @param title text
  # @param message text
  # @param type select [success, warning, error]
  # @param auto_remove toggle

  def default(title: "Notification message", message: "Here we can type a success or failure message to the user", type: 'success', auto_remove: false)
    render NotificationComponent.new(title: title, comment: message, type: type, auto_remove: auto_remove)
  end

end
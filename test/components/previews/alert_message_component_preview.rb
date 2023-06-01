class AlertMessageComponentPreview < ViewComponent::Preview

    # @param message text
    # @param type select [error, info, success, warning]

    def default(message: "Here we can type a success or failure message to the user", type: "info", closeable: true )
        render(AlertMessageComponent.new(message: message, type: type, closeable: closeable))
    end
  
end
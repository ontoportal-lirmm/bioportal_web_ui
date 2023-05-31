class CardMessageComponentPreview < ViewComponent::Preview

    # @param message text
    # @param button_text text
    # @param type select [success, failure]
    # @param button_link text

    def default(message: "Here we can type a success or failure message to the user", button_text: "Do action", type: "success", button_link: "/" )
        render(CardMessageComponent.new(message: message, button_text: button_text, type: type, button_link: button_link))
    end
  
end
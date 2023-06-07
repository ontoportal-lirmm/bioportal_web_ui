class CardMessageComponentPreview < ViewComponent::Preview

    # @param message text
    # @param button_text text
    # @param button_link text

    def default(message: "Here we can type a success or failure message to the user", button_text: "Do action", button_link: "/" )
        render(CardMessageComponent.new(message: message, button_text: button_text, type: "success", button_link: button_link))
    end
  
    
    # @param message text
    # @param button_text text
    # @param button_link text

    def warning(message: "Here we can type a success or failure message to the user", button_text: "Do action", button_link: "/" )
        render(CardMessageComponent.new(message: message, button_text: button_text, type: "warning", button_link: button_link))
    end


    # @param message text
    # @param button_text text
    # @param button_link text

    def failure(message: "Here we can type a success or failure message to the user", button_text: "Do action", button_link: "/" )
        render(CardMessageComponent.new(message: message, button_text: button_text, type: "failure", button_link: button_link))
    end


end
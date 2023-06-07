class RoundedButtonComponentPreview < ViewComponent::Preview

    # @param icon text
    # @param link text
    # @param size select [small, medium, big]

    def default(icon: "json.svg", link: "text", size: "small")
        render(RoundedButtonComponent.new(icon: icon, link: link, size: size))
    end




end
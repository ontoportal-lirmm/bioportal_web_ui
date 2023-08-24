class Buttons::ChipButtonComponentPreview < ViewComponent::Preview

    # @param url text
    # @param text text

    def standard(url: "nil", text: "text")
        render(ChipButtonComponent.new(url: url, text: text, type: "static"))
    end

    # @param url text
    # @param text text

    def clickable(url: "nil", text: "text")
        render(ChipButtonComponent.new(url: url, text: text, type: "clickable"))
    end



end
class CardMessageComponent < ViewComponent::Base
    def initialize(title: nil ,message:, button_text: nil, button_link: "/" ,type:)
        @title = title
        @message = message
        @button_text = button_text
        @type = type
        @button_link = button_link
    end

    def no_title?
        @title.nil?
    end

    def no_button?
        @button_text.nil?
    end

    def icon
        case @type
        when "success"
            "green-check.svg"
        when "failure"
            "red-warning.svg"
        end
    end
end

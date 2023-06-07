class RoundedButtonComponent < ViewComponent::Base
    def initialize(icon: "json.svg", link: "#", size: "small")
        @icon = icon
        @link = link
        @size = size
    end

    def size
        case @size
            when "small"
                ["32px", "1", "16px"]
            when "medium"
                ["64px", "2", "32px"]
            when "big"
                ["100px", "2.5", "50px"]
            end
    end

end
class ChipButtonComponent < ViewComponent::Base
    def initialize(url: nil, text:, type: "static")
        @url = url
        @text = text
        @type = type
    end
end
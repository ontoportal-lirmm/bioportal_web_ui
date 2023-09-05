class ChipButtonComponent < ViewComponent::Base
    def initialize(url: nil, text:, type: "static",  **html_options)
        @url = url
        @text = text
        @type = type
        @html_options = html_options.merge({href: @url})
    end
end
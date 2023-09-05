class ChipButtonComponent < ViewComponent::Base
    def initialize(url: nil, text: nil, type: "static", disabled: false,  **html_options)
        @url = url
        @text = text
        @type = type
        @disabled = disabled
        @html_options = html_options.merge({href: @url})
    end
end
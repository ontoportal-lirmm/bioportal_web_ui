class ChipButtonComponent < ViewComponent::Base
    def initialize(url: nil, text: nil, type: "static", disabled: false, tooltip: nil  ,**html_options)
        @url = url
        @text = text
        @type = type
        @disabled = disabled
        @tooltip = tooltip
        @html_options = html_options.merge({href: @url})
    end
end
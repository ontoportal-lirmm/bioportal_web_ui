class ChipButtonComponent < ViewComponent::Base
    def initialize(url: nil, text: nil, type: "static", disabled: false, tooltip: nil, data_turbo: 'true'  ,**html_options)
        @url = url
        @text = text
        @type = type
        @disabled = disabled
        @tooltip = tooltip
        @data_turbo = data_turbo
        @html_options = html_options.merge({href: @url})
    end
end

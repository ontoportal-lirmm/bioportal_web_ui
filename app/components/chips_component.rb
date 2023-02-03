class ChipsComponent < ViewComponent::Base
    def initialize(text:)
        @text = text
    end

    def text_underscore
        @text.parameterize(separator: '_')
    end
end
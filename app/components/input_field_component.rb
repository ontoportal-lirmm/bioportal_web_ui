class InputFieldComponent < ViewComponent::Base
    def initialize(label: , name:, type: "text", width: "100%", margin_bottom: "0px")
        @label = label
        @name = name
        @type = type
        @width = width
        @margin_bottom = margin_bottom
    end
end
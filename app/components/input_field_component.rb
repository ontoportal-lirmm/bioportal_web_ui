class InputFieldComponent < ViewComponent::Base
    def initialize(label: , name:, type: "text", choices:[], width: "100%", margin_bottom: "0px")
        @label = label
        @name = name
        @type = type
        @width = width
        @choices = choices
        @margin_bottom = margin_bottom
    end
end
class Buttons::PrimaryButtonComponent < ViewComponent::Base
    def initialize(name: "", value: ,variant: "primary", type: "regular", style: "regular", color: "primary", onclick: "")
        @name = name
        @value = value
        @variant = variant
        @type = type
        @style = style
        @color = color
        @onclick = onclick
    end
end

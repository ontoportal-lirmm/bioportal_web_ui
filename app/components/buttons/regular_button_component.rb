class Buttons::RegularButtonComponent < ViewComponent::Base
    def initialize(name: "", value: ,variant: "primary", type: "regular", style: "regular", color: "primary", icon: "", icon_type:"left", href: "#")
        @name = name
        @value = value
        @variant = variant
        @type = type
        @style = style
        @color = color
        @icon = icon
        @icon_type = icon_type
        @href = href
    end
end

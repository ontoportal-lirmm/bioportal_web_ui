class Buttons::RegularButtonComponent < ViewComponent::Base
    def initialize(name: "", value: ,variant: "primary", type: "regular", style: "regular", color: "normal", icon: "", icon_type:"left", href: "#", size: "normal")
        @name = name
        @value = value
        @variant = variant
        @type = type
        @style = style
        @color = color
        @icon = icon
        @icon_type = icon_type
        @href = href
        @size = size
    end
end

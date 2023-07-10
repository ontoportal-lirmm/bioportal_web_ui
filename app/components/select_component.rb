class SelectComponent < ViewComponent::Base
    def initialize(label: , name:, choices:, width: "100%", margin_bottom: "0px" )
        @label = label
        @name = name
        @choices = choices
        @width = width
        @margin_bottom = margin_bottom
    end
end
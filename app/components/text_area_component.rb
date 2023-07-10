class TextAreaComponent < ViewComponent::Base
    def initialize(label: , name:, width: "100%", margin_bottom: "0px" )
        @label = label
        @name = name
        @width = width
        @margin_bottom = margin_bottom
    end
end
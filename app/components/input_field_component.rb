class InputFieldComponent < ViewComponent::Base
    def initialize(label: "" , name:, type: "text", choices:[], hint: "")
        @label = label
        @name = name
        @type = type
        @choices = choices
        @hint  = hint
    end
end
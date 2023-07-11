class InputFieldComponent < ViewComponent::Base
    def initialize(label: "" , name:, type: "text", choices:[], hint: "", error_message: "")
        @label = label
        @name = name
        @type = type
        @choices = choices
        @hint  = hint
        @error_message = error_message
    end
end
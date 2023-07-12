class InputFieldComponent < ViewComponent::Base
    def initialize(label: "" , name:, type: "text", choices:[], hint: "", error_message: "", helper_text: "")
        @label = label
        @name = name
        @type = type
        @choices = choices
        @hint  = hint
        @error_message = error_message
        @helper_text = helper_text
    end
end



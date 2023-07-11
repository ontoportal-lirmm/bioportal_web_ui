class InputFieldComponent < ViewComponent::Base
    def initialize(label: , name:, type: "text", choices:[])
        @label = label
        @name = name
        @type = type
        @choices = choices
    end
end
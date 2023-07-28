class InputFieldComponent < ViewComponent::Base
    def initialize(label: "" , name:, value: 'Syphax', type: 'text', placeholder: "", error_message: "", helper_text: "")
        @label = label
        @name = name
        @placeholder  = placeholder
        @error_message = error_message
        @helper_text = helper_text
        @value = value
        @type = type
    end


    def error_style
        "border-color: var(--error-color);" if error?
    end

    def error?
        !@error_message.empty?
    end

    def help?
        !@helper_text.empty?
    end

    def label?
        !@label.empty?
    end
end



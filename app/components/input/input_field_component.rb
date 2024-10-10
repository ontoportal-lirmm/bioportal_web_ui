class Input::InputFieldComponent < ViewComponent::Base
    def initialize(label: "" , name:, value: '', type: 'text', placeholder: "", error_message: "", helper_text: "", disabled: false, data: nil, id: '', min: '', max: '', step: '', tooltip: nil)
        @label = label
        @name = name
        @placeholder  = placeholder
        @error_message = error_message
        @helper_text = helper_text
        @value = value
        @type = type
        @disabled = disabled
        @id = id
        @data = data
        @min = min
        @max = max
        @step = step
        @tooltip = tooltip
    end


    def error_style
        "border-color: var(--error-color);" if error?
    end

    def error?
        !@error_message&.empty?
    end

    def help?
        !@helper_text.blank?
    end

    def label?
        !@label&.empty?
    end
end



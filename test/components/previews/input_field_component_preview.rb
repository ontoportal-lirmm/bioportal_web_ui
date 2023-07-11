class InputFieldComponentPreview < ViewComponent::Preview


    


    # This is a text input field:
    # - To use it without a label: don't give a value to the param label or leave it empty.
    # - To give it a hint (placeholder): define the param hint with the hind you want to be displayed.
    # - To put it in error state: define the param error_message with the error message you want to be displayed.
    # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
    # @param label text    
    # @param hint text
    # @param error_message text
    # @param helper_text text

    def default(label: "Label", hint: "", error_message: "", helper_text: "")
        render InputFieldComponent.new(label: label, name: "name", type: "text", hint: hint, error_message: error_message, helper_text: helper_text)
    end


    # This is a textarea field:
    # - To use it without a label: don't give a value to the param label or leave it empty.
    # - To give it a hint (placeholder): define the param hint with the hind you want to be displayed.
    # - To put it in error state: define the param error_message with the error message you want to be displayed.
    # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
    # @param label text    
    # @param hint text
    # @param error_message text
    # @param helper_text text

    def textarea(label: "Label", hint: "", error_message: "", helper_text: "")
        render InputFieldComponent.new(label: label, name: "name", type: "textarea", hint: hint, error_message: error_message, helper_text: helper_text)
    end



    # This is a date input field:
    # - To use it without a label: don't give a value to the param label or leave it empty.
    # - To put it in error state: define the param error_message with the error message you want to be displayed.
    # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
    # @param label text   
    # @param error_message text
    # @param helper_text text

    def date(label: "Label", error_message: "", helper_text: "")
        render InputFieldComponent.new(label: label, name: "name", type: "date", error_message: error_message, helper_text: helper_text)
    end

    # This is a text input field:
    # - To use it without a label: don't give a value to the param label or leave it empty.
    # - To put it in error state: define the param error_message with the error message you want to be displayed.
    # - To give it a helper text (a text displayed under the input field): define the param helper_text with the helper text you want to be displayed.
    # @param label text   
    # @param error_message text 
    # @param helper_text text

    def select(label: "Label", error_message: "", helper_text: "")
        render InputFieldComponent.new(label: label, name: "name", type: "select", choices: ["choice 1", "choice 2", "choice 3"], error_message: error_message, helper_text: helper_text)
    end


end 
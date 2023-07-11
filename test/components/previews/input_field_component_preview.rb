class InputFieldComponentPreview < ViewComponent::Preview


    # @param label text    
    # @param hint text
    # @param error_message text

    def default(label: "Label", hint: "", error_message: "")
        render InputFieldComponent.new(label: label, name: "name", type: "text", hint: hint, error_message: error_message)
    end


    # @param label text   
    # @param error_message text 

    def date(label: "Label", error_message: "")
        render InputFieldComponent.new(label: label, name: "name", type: "date", error_message: error_message)
    end


    # @param label text   
    # @param error_message text 

    def select(label: "Label", error_message: "")
        render InputFieldComponent.new(label: label, name: "name", type: "select", choices: ["choice 1", "choice 2", "choice 3"], error_message: error_message)
    end


end 
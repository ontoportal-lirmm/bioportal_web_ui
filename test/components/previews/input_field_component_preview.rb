class InputFieldComponentPreview < ViewComponent::Preview


    # @param label text    
    # @param hint text

    def default(label: "Label", hint: "")
        render InputFieldComponent.new(label: label, name: "name", type: "text", hint: hint)
    end


    # @param label text   

    def date(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "date")
    end


    # @param label text   

    def select(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "select", choices: ["bilel", "kihal", "best"])
    end


end 
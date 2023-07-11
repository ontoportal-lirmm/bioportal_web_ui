class InputFieldComponentPreview < ViewComponent::Preview

    # @param label text    
    
    def default(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "text")
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
class InputFieldComponentPreview < ViewComponent::Preview

    # @param label text    
    
    def default(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "text", width: "100%", margin_bottom: "0")
    end

    # @param label text   

    def date(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "date", width: "100%", margin_bottom: "0")
    end

    # @param label text   

    def select(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "select", choices: ["bilel", "kihal", "best"], width: "100%", margin_bottom: "0")
    end


end 
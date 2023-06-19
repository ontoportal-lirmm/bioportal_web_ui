class InputFieldComponentPreview < ViewComponent::Preview

    # @param label text    
    
    def default(label: "Label")
        render InputFieldComponent.new(label: label, name: "name", type: "text", width: "100%", margin_bottom: "0")
    end
  
end
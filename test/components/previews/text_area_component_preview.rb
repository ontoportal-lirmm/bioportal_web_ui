class TextAreaComponentPreview < ViewComponent::Preview

    # @param label text    
    
    def default(label: "Label")
        render TextAreaComponent.new(label: label, name: "name", width: "100%", margin_bottom: "0")
    end
  
end
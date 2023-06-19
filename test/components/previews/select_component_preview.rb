class SelectComponentPreview < ViewComponent::Preview

    # @param label text
    
    def default(label: "Label")
        render SelectComponent.new(label: label, name: "name", choices: ["choice 1", "choice 2", "choice 3"], width: "100%", margin_bottom: "0")
    end
  
end
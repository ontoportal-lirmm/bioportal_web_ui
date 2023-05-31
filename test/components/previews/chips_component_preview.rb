class ChipsComponentPreview < ViewComponent::Preview

    # @param name text
    # @param value text
    
    def default(name: "name", value: "value")
        render(ChipsComponent.new(name: name, value: value))
    end
  
end
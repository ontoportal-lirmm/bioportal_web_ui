class Input::FileInputComponentPreview < ViewComponent::Preview

    
    def default
        render Input::FileInputComponent.new(name: "file")
    end


end 
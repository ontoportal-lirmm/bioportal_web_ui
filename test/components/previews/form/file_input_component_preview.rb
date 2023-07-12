class Form::FileInputComponentPreview < ViewComponent::Preview

    
    def default
        render Form::FileInputComponent.new(name: "file")
    end


end 
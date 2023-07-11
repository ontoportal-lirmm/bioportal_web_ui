class Inputs::FileInputLoaderComponentPreview < ViewComponent::Preview

    
    def default
        render FileInputLoaderComponent.new(name: "file")
    end


end 
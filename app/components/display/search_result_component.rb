
class Display::SearchResultComponent < ViewComponent::Base
    renders_many :subresults, Display::SearchResultComponent
    
    def initialize(title: nil, uri: nil, text: nil, other_reuses: nil, is_sub_component: false)
        @title = title
        @uri = uri
        @text = text
        @other_reuses = other_reuses
        @is_sub_component = is_sub_component
    end

    def sub_component_class
        @is_sub_component ? 'sub-component' : ''
    end
end
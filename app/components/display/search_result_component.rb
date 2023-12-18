
class Display::SearchResultComponent < ViewComponent::Base
    renders_many :subresults, Display::SearchResultComponent
    
    def initialize(title: nil, uri: nil, definition: nil, link: nil, other_reuses: nil, is_sub_component: false, sub_number: 0, mappings: 0)
        @title = title
        @uri = uri
        @definition = definition
        @link = link
        @other_reuses = other_reuses
        @is_sub_component = is_sub_component
        @sub_number = sub_number
        @mappings = mappings
    end

    def sub_component_class
        @is_sub_component ? 'sub-component' : ''
    end
end
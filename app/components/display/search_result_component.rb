
class Display::SearchResultComponent < ViewComponent::Base
    include ModalHelper
    renders_many :subresults, Display::SearchResultComponent
    renders_many :reuses, Display::SearchResultComponent
    def initialize(title: nil, ontology_acronym: nil ,uri: nil, definition: nil, link: nil,  is_sub_component: false)
        @title = title
        @uri = uri
        @definition = definition
        @link = link
        @is_sub_component = is_sub_component
        @ontology_acronym = ontology_acronym
    end

    def sub_component_class
        @is_sub_component ? 'sub-component' : ''
    end
end
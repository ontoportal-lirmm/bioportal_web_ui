
class Display::SearchResultComponent < ViewComponent::Base
    include ModalHelper
    include ApplicationHelper
    renders_many :subresults, Display::SearchResultComponent
    renders_many :reuses, Display::SearchResultComponent
    def initialize(title: nil, ontology_acronym: nil ,uri: nil, definition: nil, link: nil, other_reuses: nil, is_sub_component: false, sub_number: 0, reuses: 0)
        @title = title
        @uri = uri
        @definition = definition
        @link = link
        @other_reuses = other_reuses
        @is_sub_component = is_sub_component
        @sub_number = sub_number
        @reuses = reuses
        @ontology_acronym = ontology_acronym
    end

    def sub_component_class
        @is_sub_component ? 'sub-component' : ''
    end
end
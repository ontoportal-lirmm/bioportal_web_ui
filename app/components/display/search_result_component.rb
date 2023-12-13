class Display::SearchResultComponent < ViewComponent::Base
    def initialize(title: nil, uri: nil, text: nil, more_from_ontology: nil)
        @title = title
        @uri = uri
        @text = text
        @more_from_ontology = more_from_ontology
    end
end
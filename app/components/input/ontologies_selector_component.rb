class Input::OntologiesSelectorComponent < ViewComponent::Base
    include ModalHelper
    def initialize(id: , label: nil,ontologies: ,name: nil, selected: nil)  
        @id = id
        @label = label
        @ontologies = ontologies
        @name = name
        @selected = selected
    end
end
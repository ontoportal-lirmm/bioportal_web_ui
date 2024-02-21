class Input::OntologiesSelectorComponent < ViewComponent::Base
    include ModalHelper
    def initialize(id: ,ontologies: ,name: nil, selected: nil)  
        @id = id
        @ontologies = ontologies
        @name = name
        @selected = selected
    end
end
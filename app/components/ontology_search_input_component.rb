# frozen_string_literal: true

class OntologySearchInputComponent < ViewComponent::Base

  def initialize(name: 'search', placeholder: t('ontologies.ontology_search_prompt'), scroll_down: true)
    @name = name
    @placeholder = placeholder
    @scroll_down = scroll_down
  end
end

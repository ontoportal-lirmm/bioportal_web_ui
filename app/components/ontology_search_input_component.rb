# frozen_string_literal: true

class OntologySearchInputComponent < ViewComponent::Base
  include InternationalisationHelper

  def initialize(name: 'search', placeholder: t('ontologies.ontology_search_prompt'), scroll_down: true, search_icon_type: nil)
    @name = name
    @placeholder = placeholder
    @scroll_down = scroll_down
    @search_icon_type = search_icon_type
  end
end

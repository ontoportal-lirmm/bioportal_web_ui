# frozen_string_literal: true

class OntologySearchInputComponent < ViewComponent::Base

  def initialize(name: 'search', placeholder: 'Search for an ontology or concept (Ex: Agrovoc ...)', scroll_down: true)
    @name = name
    @placeholder = placeholder
    @scroll_down = scroll_down
  end
end

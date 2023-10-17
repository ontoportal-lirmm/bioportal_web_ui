# frozen_string_literal: true

class OntologySearchInputComponent < ViewComponent::Base

  def initialize(name: 'search', placeholder: 'Search an ontology (e.g., Agrovoc) or concept (e.g., plant height)', scroll_down: true)
    @name = name
    @placeholder = placeholder
    @scroll_down = scroll_down
  end
end

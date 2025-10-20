# frozen_string_literal: true

class SubjectsSearchInputComponent < ViewComponent::Base

  def initialize(attr:, attr_key:, values: [], ontologies: [])
    @attr = attr
    @attr_key = attr_key
    @values = values
    @ontologies = ontologies
  end
end

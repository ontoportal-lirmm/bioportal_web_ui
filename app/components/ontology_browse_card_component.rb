# frozen_string_literal: true

class OntologyBrowseCardComponent < ViewComponent::Base

  def initialize(ontology: nil)
    super
    @ontology = ontology
  end

  def ontology
    @ontology
  end
end

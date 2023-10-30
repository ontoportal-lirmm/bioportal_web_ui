# frozen_string_literal: true

class OntologyBrowseCardComponent < ViewComponent::Base
  include OntologiesHelper

  def initialize(ontology: nil)
    super
    @ontology = ontology
  end

  def ontology
    @ontology
  end
end

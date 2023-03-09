class History
  attr_accessor :ontology_id, :ontology_name, :ontology_acronym, :concept

  def initialize(ontology_id, ontology_name, ontology_acronym, concept)
    self.ontology_id = ontology_id
    self.ontology_name = ontology_name
    self.ontology_acronym = ontology_acronym
    self.concept = concept
  end
end

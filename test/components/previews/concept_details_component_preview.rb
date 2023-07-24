# frozen_string_literal: true

class ConceptDetailsComponentPreview < ViewComponent::Preview
  def default
    properties = { links: nil,
                   context: nil,
                   "http://www.w3.org/2004/02/skos/core#narrower": ["http://opendata.inrae.fr/thesaurusINRAE/d_0101",
                                                                    "http://opendata.inrae.fr/thesaurusINRAE/d_0103",
                                                                    "http://opendata.inrae.fr/thesaurusINRAE/d_0102",
                                                                    "http://opendata.inrae.fr/thesaurusINRAE/d_0104",
                                                                    "http://opendata.inrae.fr/thesaurusINRAE/d_0105"],
                   "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": ["http://www.w3.org/2004/02/skos/core#Concept",
                                                                       "http://www.w3.org/2002/07/owl#NamedIndividual"],
                   "http://www.w3.org/2004/02/skos/core#topConceptOf": ["http://opendata.inrae.fr/thesaurusINRAE/thesaurusINRAE"],
                   "http://www.w3.org/2004/02/skos/core#prefLabel": ["01. ENVIRONMENT [domain]"],
                   "http://www.w3.org/2004/02/skos/core#inScheme": ["http://opendata.inrae.fr/thesaurusINRAE/thesaurusINRAE"],
                   "http://purl.org/dc/terms/modified": ["2021-02-24T15:25:56"]
    }
    schemes_keys = %w[hasTopConcept topConceptOf]
    label_xl_set = %w[skos-xl#prefLabel skos-xl#altLabel skos-xl#hiddenLabel]
    render ConceptDetailsComponent.new(id: 'concept-details', acronym: "Ontology",
                                       properties: OpenStruct.new(properties),
                                       top_keys: %w[description comment],
                                       bottom_keys: %w[disjoint subclass is_a has_part],
                                       exclude_keys: schemes_keys + label_xl_set + ['inScheme']) do |c|
      c.header(stripped: true) do |table|
        table.add_row({ th: 'ID' }, { td: "http://opendata.inrae.fr/thesaurusINRAE/d_1" })
        table.add_row({ th: 'Preferred Name' }, { td: "01. ENVIRONMENT [domain]" })
        table.add_row({ th: 'Type' }, { td: "http://www.w3.org/2004/02/skos/core#Concept" })
      end
    end
  end
end

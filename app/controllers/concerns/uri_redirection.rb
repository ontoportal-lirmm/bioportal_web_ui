# frozen_string_literal: true

module UriRedirection
    extend ActiveSupport::Concern

    
    def find_type_by_id(id, acronym)
        type, resource_id = find_type_by_search(id, acronym)
        return type, resource_id if type

        type, resource_id = find_type_by_metadata(id, acronym)
        return type, resource_id if type

        return nil, nil
    end

    def find_type_by_search(id, acronym)
        result = LinkedData::Client::HTTP.get('search/ontologies/content', { q: "*#{id}", qf: "resource_id", page: 1, pagesize: 10, ontologies: acronym })
        if result[:collection].empty?
          type = nil
          resource_id = nil
        else
          type = id_type(result[:collection][0][:type_t], result[:collection][0][:type_txt])
          resource_id = result[:collection][0][:resource_id]
        end
        [type, result[:collection][0][:resource_id]]
    end

    def find_type_by_metadata(id, acronym)
        return nil, nil # TODO maybe implimented if needed
    end

    private
    def supported_types
        %w[Concept Class Ontology ConceptScheme Collection NamedIndividual AnnotationProperty ObjectProperty DatatypeProperty]
    end

    def id_type(type_t, type_txt)
    
        type = (Array(type_t) + Array(type_txt)).map { |x| helpers.link_last_part(x) }
                                                .select{|x| supported_types.include?(x)}
    
        type = Array(type).reject { |x| x.eql?("NamedIndividual") } if (Array(type).size > 1)
    
        type.first
    end

    def link_by_type(id, ontology, type)
        case type
        when 'Concept', 'Class'
          ontology_path(id: ontology, p: 'classes', conceptid: id)
        when 'Ontology'
          ontology_path(id: ontology, p: 'summary')
        when 'ConceptScheme'
          ontology_path(id: ontology, p: 'schemes', schemeid: id)
        when 'Collection'
          ontology_path(id: ontology, p: 'collections', collectionid: id)
        when 'NamedIndividual'
          ontology_path(id: ontology, p: 'instances', instanceid: id)
        when 'AnnotationProperty', 'ObjectProperty', 'DatatypeProperty'
          ontology_path(id: ontology, p: 'properties', instanceid: id)
        else
          ontology_path(id: ontology, p: 'summary')
        end
    end
    
end  
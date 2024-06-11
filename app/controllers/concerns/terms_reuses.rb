module TermsReuses
    extend ActiveSupport::Concern

    def get_submission_uri_pattern_by_id(acronym: nil)
        LinkedData::Client::HTTP.get("ontologies/#{acronym}/latest_submission", {display: 'uriRegexPattern,preferredNamespaceUri'})
    end

    def concept_reused?(ontology_uri_pattern: nil, concept_id: nil)
        if ontology_uri_pattern&.uriRegexPattern 
            is_reused = !(concept_id =~ Regexp.new(ontology_uri_pattern.uriRegexPattern))
        elsif ontology_uri_pattern&.preferredNamespaceUri 
            is_reused = !(concept_id.include?(ontology_uri_pattern.preferredNamespaceUri))
        end
        return is_reused
    end

end
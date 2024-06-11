module TermsReuses
    extend ActiveSupport::Concern

    def ontology_uri_pattern(ontology: nil, submission: nil, acronym: nil)
        if ontology
            raw_ontology_uri_pattern = ontology.explore.latest_submission(include:'uriRegexPattern,preferredNamespaceUri') 
            ontology_uri_pattern = [raw_ontology_uri_pattern.uriRegexPattern, raw_ontology_uri_pattern.preferredNamespaceUri]
        elsif submission
            ontology_uri_pattern = [@submission.uriRegexPattern, @submission.preferredNamespaceUri]
        elsif acronym
            raw_ontology_uri_pattern = LinkedData::Client::HTTP.get("ontologies/#{acronym}/latest_submission", {display: 'uriRegexPattern,preferredNamespaceUri'})
            ontology_uri_pattern = [raw_ontology_uri_pattern.uriRegexPattern, raw_ontology_uri_pattern.preferredNamespaceUri]
        end

        return ontology_uri_pattern
    end

    def is_reused(ontology_uri_pattern:, concept_id:)
        if ontology_uri_pattern[0] # if uriRegexPattern exists
          is_reused = !(concept_id =~ Regexp.new(ontology_uri_pattern[0]))
        elsif ontology_uri_pattern[1] # if preferredNamespaceUri exists
          is_reused = !(concept_id.include?(ontology_uri_pattern[1]))
        end
    end

end
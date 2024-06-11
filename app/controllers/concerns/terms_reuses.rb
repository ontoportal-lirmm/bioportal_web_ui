module TermsReuses
    extend ActiveSupport::Concern

    def get_submission_uri_pattern_by_id(acronym: nil)
        LinkedData::Client::HTTP.get("ontologies/#{acronym}/latest_submission", {display: 'uriRegexPattern,preferredNamespaceUri'})
    end

    def concept_reused?(submission: nil, concept_id: nil)
        if submission&.uriRegexPattern 
            is_reused = !(concept_id =~ Regexp.new(submission.uriRegexPattern))
        elsif submission&.preferredNamespaceUri 
            is_reused = !(concept_id.include?(submission.preferredNamespaceUri))
        end
        return is_reused
    end

end
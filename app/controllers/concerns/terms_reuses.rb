module TermsReuses
    extend ActiveSupport::Concern

    def concept_reused?(submission: nil, concept_id: nil)
        uri_regex_pattern?(submission, concept_id) || preffered_namespace_uri?(submission, concept_id)
    end

    private
    def uri_regex_pattern?(submission, concept_id)
        !(concept_id =~ Regexp.new(submission&.uriRegexPattern || ''))
    end
    def preffered_namespace_uri?(submission, concept_id)
        !(concept_id.include?(submission&.preferredNamespaceUri || ''))
    end
end

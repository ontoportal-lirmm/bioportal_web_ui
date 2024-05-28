class SubmissionStatusComponent < ViewComponent::Base
  include OntologiesHelper

  def initialize(submission, latest)
    @submission = submission
    @latest = latest
  end

  def submission_version
    @submission.version.to_s if @submission.version.present? 
  end

  def submission_link
    if @submission.version.present?
      if @submission.ontology.summaryOnly || !@latest
        submission_version
      else
        link_to submission_version, ontology_path(@submission.ontology.acronym)
      end
    end
  end

  def submission_status
    return unless @submission.submissionStatus.present?
    statuses = submission_status2string(@submission)
  end

end
  
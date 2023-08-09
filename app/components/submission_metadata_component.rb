# frozen_string_literal: true

class SubmissionMetadataComponent < ViewComponent::Base
  include ApplicationHelper, MetadataHelper, AgentHelper, OntologiesHelper

  def initialize(submission: )
    super
    @submission = submission

    @json_metadata = submission_metadata
    metadata_list = {}
    # Get extracted metadata and put them in a hash with their label, if one, as value
    @json_metadata.each do |metadata|
      if metadata["extracted"] == true
        metadata_list[metadata["attribute"]] = metadata["label"]
      end
    end

    @metadata_list = metadata_list.sort
    @metadata_not_displayed = ["status", "description", "documentation", "publication", "homepage", "openSearchDescription", "dataDump", "includedInDataCatalog", "logo", "depiction"]
  end
end

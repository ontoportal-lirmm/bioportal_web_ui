# frozen_string_literal: true

class SubmissionMetadataComponent < ViewComponent::Base
  include ApplicationHelper, MetadataHelper, SubmissionInputsHelper,OntologiesHelper, AgentHelper

  def initialize(submission: , submission_metadata:)
    super
    @submission = submission

    @json_metadata = submission_metadata
    metadata_list = {}
    # Get extracted metadata and put them in a hash with their label, if one, as value
    @json_metadata.each do |metadata|
      metadata_list[metadata["attribute"]] = metadata["label"]
    end
    reject = [:csvDump, :dataDump, :openSearchDescription, :metrics, :prefLabelProperty, :definitionProperty,
              :definitionProperty, :synonymProperty, :authorProperty, :hierarchyProperty, :obsoleteProperty,
              :ontology, :endpoint, :submissionId, :submissionStatus, :uploadFilePath]
    @metadata_list = metadata_list.reject{|k,v| reject.include?(k.to_sym)}.sort
  end

  def display_attributes(metadata)
    if Array(@submission.send(metadata)).empty?
      out = 'N/A'
    else
      out = Array(@submission.send(metadata)).map do |value|
        content_tag(:div, class: 'm-1 f32') do
          display_attribute(metadata, value)
        end
      end.join
    end
    out.html_safe
  end
end

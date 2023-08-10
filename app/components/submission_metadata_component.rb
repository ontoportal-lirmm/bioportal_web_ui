# frozen_string_literal: true

class SubmissionMetadataComponent < ViewComponent::Base
  include ApplicationHelper, MetadataHelper,OntologiesHelper, AgentHelper

  def initialize(submission: , submission_metadata:)
    super
    @submission = submission

    @json_metadata = submission_metadata
    metadata_list = {}
    # Get extracted metadata and put them in a hash with their label, if one, as value
    @json_metadata.each do |metadata|
      metadata_list[metadata["attribute"]] = metadata["label"]
    end

    @metadata_list = metadata_list.sort
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
  def attribute_help_text(attr)
    if !attr["namespace"].nil?
      help_text = "<strong>#{attr["namespace"]}:#{attr["attribute"]}</strong>"
    else
      help_text = "<strong>bioportal:#{attr["attribute"]}</strong>"
    end

    if (attr["metadataMappings"] != nil)
      help_text += " (#{attr["metadataMappings"].join(", ")})"
    end

    if (!attr["enforce"].nil? && attr["enforce"].include?("uri"))
      help_text += "<br/>This metadata should be an <strong>URI</strong>"
    end

    if (attr["helpText"] != nil)
      help_text += "<br/><br/>#{attr["helpText"]}"
    end
    help_text.html_safe
  end
end

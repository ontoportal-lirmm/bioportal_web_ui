# frozen_string_literal: true

class EditSubmissionAttributeButtonComponent < ViewComponent::Base
  include ActionView::Helpers::TagHelper

  def initialize(acronym: , submission_id:, attribute:, inline: false)
    @acronym = acronym
    @submission_id  = submission_id
    @attribute = attribute

    if inline
      @link = "ontologies_metadata_curator/#{@acronym}/submissions/#{@submission_id}?properties=#{@attribute}&inline_save=true"
    else
      @link = "/ontologies/#{@acronym}/submissions/#{@submission_id}/edit?properties=#{@attribute}"
    end
  end

  def call
    link_to @link, data: {turbo: true},  class: "btn btn-sm btn-light" do
      content
    end
  end

end

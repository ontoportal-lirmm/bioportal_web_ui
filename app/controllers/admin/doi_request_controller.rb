class Admin::DoiRequestController < ApplicationController

  include DoiRequest, TurboHelper

  def index
  end

  def show
    @ontology = LinkedData::Client::Models::Ontology.get(params[:ontology_id]) rescue nil

    ontology_not_found(params[:ontology_id]) unless @ontology

    @submission = @ontology.explore.latest_submission

    @identifier_request = first_pending_doi_request
  end

  def create
    @ontology = LinkedData::Client::Models::Ontology.get(params[:ontology_id]) rescue nil

    ontology_not_found(params[:ontology_id]) unless @ontology

    @submission = @ontology.explore.latest_submission

    ontology_not_found(params[:ontology_id]) unless @submission

    @identifier_request = submit_new_doi_request(@submission.id)

    if response_error?(@identifier_request)
      render_turbo_stream alert_error(id: "#{@ontology.acronym}_doi_request") { "An error occurred while creating the DOI request" }
    else
      render_turbo_stream replace("#{@ontology.acronym}_doi_request") { render_to_string('admin/doi_request/show', layout: nil) }
    end
  end

  def update
    @ontology = LinkedData::Client::Models::Ontology.get(params[:ontology_id]) rescue nil

    ontology_not_found(params[:ontology_id]) unless @ontology

    cancel_pending_doi_requests

    render_turbo_stream replace("#{@ontology.acronym}_doi_request") { render_to_string('admin/doi_request/show', layout: nil) }
  end

end

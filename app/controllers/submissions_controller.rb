class SubmissionsController < ApplicationController
  include SubmissionsHelper, SubmissionUpdater
  layout :determine_layout
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]
  before_action :submission_metadata, only: [:create, :edit, :new, :update]

  # When getting "Add submission" form to display
  def new
    @ontology = LinkedData::Client::Models::Ontology.get(CGI.unescape(params[:ontology_id])) rescue nil
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first unless @ontology
    @submission = @ontology.explore.latest_submission
    @submission ||= LinkedData::Client::Models::OntologySubmission.new
  end

  # Called when form to "Add submission" is submitted
  def create
    # Make the contacts an array
    _, submission_params =  params[:submission].each.first

    @submission_saved = save_submission(submission_params)
    if response_error?(@submission_saved)
      @errors = response_errors(@submission_saved) # see application_controller::response_errors

      if @errors[:error] && @errors[:error][:uploadFilePath]
        @errors = ["Please specify the location of your ontology"]
      elsif @errors[:error] && @errors[:error][:contact]
        @errors = ["Please enter a contact"]
      end

      render "new"
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  # Called when form to "Edit submission" is submitted
  def edit
    display_submission_attributes params[:ontology_id], params[:properties]&.split(','), submissionId: params[:id],
                                  required: params[:required]&.eql?('true'),
                                  show_sections: params[:show_sections].nil? || params[:show_sections].eql?('true'),
                                  inline_save: params[:inline_save]&.eql?('true')
  end

  # When editing a submission (called when submit "Edit submission information" form)
  def update
    error_responses = []
    _, submission_params = params[:submission].each.first

    error_responses << update_submission(submission_params)

    if error_responses.compact.any? { |x| x.status != 204 }
      @errors = error_responses.map { |error_response| response_errors(error_response) }
    end

    if params[:attribute]
      render_submission_attribute(params[:attribute])
    else
      redirect_to "/ontologies/#{@ontology.acronym}"
    end

  end

end

class SubmissionsController < ApplicationController
  include SubmissionsHelper, SubmissionUpdater, OntologyUpdater
  layout :determine_layout
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]
  before_action :submission_metadata, only: [:create, :edit, :new, :update, :index]


  def index
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first

    ontology_not_found(params[:ontology_id]) if @ontology.nil?

    @ont_restricted = ontology_restricted?(@ontology.acronym)

    # Retrieve submissions in descending submissionId order (should be reverse chronological order)
    @submissions = @ontology.explore.submissions({include: "submissionId,creationDate,released,modificationDate,submissionStatus,hasOntologyLanguage,version,diffFilePath,ontology"})
                            .sort {|a,b| b.submissionId.to_i <=> a.submissionId.to_i } || []

    LOG.add :error, "No submissions for ontology: #{@ontology.id}" if @submissions.empty?

  end

  # When getting "Add submission" form to display
  def new
    @required_only = params[:required].nil? || !params[:required]&.eql?('false')
    @ontology = LinkedData::Client::Models::Ontology.get(CGI.unescape(params[:ontology_id])) rescue nil
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first unless @ontology
    @submission = @ontology.explore.latest_submission
    @submission ||= LinkedData::Client::Models::OntologySubmission.new
    @submission.id = nil
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    @is_update_ontology = true
  end

  # Called when form to "Add submission" is submitted
  def create
    @is_update_ontology = true
    add_ontology_submission(params[:ontology][:acronym] || params[:id])
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

    if @errors && !params[:attribute]
      @required_only = !params['required-only'].nil?
      @filters_disabled = true
      reset_agent_attributes
      render 'edit', status: 422
    elsif params[:attribute]
      reset_agent_attributes
      render_submission_attribute(params[:attribute])
    else
      redirect_to "/ontologies/#{@ontology.acronym}"
    end

  end

  private

  def reset_agent_attributes
    helpers.agent_attributes.each do |attr|
      current_val = @submission.send(attr)
      new_values = Array(current_val).map { |x| LinkedData::Client::Models::Agent.find(x) }

      new_values = new_values.first unless current_val.is_a?(Array)

      @submission.send("#{attr}=", new_values)
    end
  end

end

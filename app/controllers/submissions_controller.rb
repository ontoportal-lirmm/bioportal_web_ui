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
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    @submission = @ontology.explore.latest_submission || LinkedData::Client::Models::OntologySubmission.new
    @submission.id = nil
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    @is_update_ontology = true
    render "ontologies/new"
  end

  # Called when form to "Add submission" is submitted
  def create
    @is_update_ontology = true

    if params[:ontology]
      @ontology = update_existent_ontology(params[:ontology_id])

      if @ontology.nil? || response_error?(@ontology)
        show_new_errors(@ontology)
        return
      end
    end

    @submission = save_submission(new_submission_hash)

    if response_error?(@submission)
      show_new_errors(@submission)
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  # Called when form to "Edit submission" is submitted
  def edit_properties
    display_submission_attributes params[:ontology_id], params[:properties]&.split(','), submissionId: params[:submission_id],
                                  inline_save: params[:inline_save]&.eql?('true')

    attribute_template_output = render_to_string(inline: helpers.render_submission_inputs(params[:container_id] || 'metadata_by_ontology'))

    render inline: attribute_template_output

  end

  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    ontology_not_found(params[:ontology_id]) unless @ontology
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    @is_update_ontology = true
  end

  # When editing a submission (called when submit "Edit submission information" form)
  def update
    acronym = params[:ontology_id]
    submission_id = params[:id]
    if params[:ontology]
      @ontology = update_existent_ontology(acronym)
      if @ontology.nil? || response_error?(@ontology)
        show_new_errors(@ontology, partial: 'submissions/form_content', locals: { id: 'test' })
        return
      end
    end

    if params[:submission].nil?
      return redirect_to "/ontologies/#{acronym}",
                         notice: 'Submission updated successfully'
    end

    @submission = update_submission(update_submission_hash(acronym), submission_id)
    #reset_agent_attributes
    if params[:attribute].nil?
      if response_error?(@submission)
        show_new_errors(@submission, partial: 'submissions/form_content', locals: { id: 'test' })
      else
        redirect_to "/ontologies/#{acronym}",
                    notice: 'Submission updated successfully'
      end
    else
      @errors = response_errors(@submission) if response_error?(@submission)
      @submission = submission_from_params(params[:submission])
      @submission.submissionId = submission_id
      render_submission_attribute(params[:attribute])
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

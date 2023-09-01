class OntologiesMetadataCuratorController < ApplicationController
  include TurboHelper, SubmissionsHelper, ActionView::Helpers::FormHelper
  include SubmissionUpdater
  layout :determine_layout
  before_action :submission_metadata, only: [:result, :edit, :update, :show_metadata_by_ontology]

  def result
    @ontologies_ids = params[:ontology] ? params[:ontology][:ontologyId] : []
    @metadata_sel = params[:search] ? params[:search][:metadata] : []
    @show_submissions = !params[:show_submissions].nil?
    @ontologies = []
    @submissions = []

    if @ontologies_ids.nil? || @ontologies_ids.empty?
      @ontologies = LinkedData::Client::Models::Ontology.all
    else
      @ontologies_ids.each do |data|
        @ontologies << LinkedData::Client::Models::Ontology.find_by_acronym(data).first
      end
    end

    display_attribute = equivalent_properties(@metadata_sel) + %w[submissionId]
    @ontologies.each do |ont|
      if @show_submissions
        submissions = ont.explore.submissions({ include: display_attribute.join(',') })
      else
        submissions = [ont.explore.latest_submission({ include: display_attribute.join(',') })]
      end
      submissions.each { |sub| append_submission(ont, sub) }
    end

    respond_to do |format|
      format.html { redirect_to admin_index_path }
      format.turbo_stream { render turbo_stream: [
        replace("selection_metadata_form", partial: "ontologies_metadata_curator/metadata_table"),
        replace('edit_metadata_btn') do
          "
           #{helpers.button_tag("Start bulk edit", onclick: 'showEditForm(event)', class: "btn btn-outline-primary mx-1 w-100")}
           #{raw helpers.help_tooltip('To use the bulk edit select in the table submissions (the rows) and metadata properties (the columns) for which you want to edit')}
          ".html_safe
        end
      ]}
    end
  end

  def show_metadata_by_ontology
    @acronym = params[:ontology]
    inline_save = params[:inline_save] && params[:inline_save].eql?('true')
    display_submission_attributes(@acronym, params[:properties]&.split(','),
                                  submissionId: params[:submission_id], inline_save: inline_save)
    render partial: 'submissions/form_content', locals: { id: params[:form_id] || '', acronym: @acronym, submissionId: params[:submission_id] }
  end

  def show_metadata_value
    acronym = params[:ontology]
    attribute = params[:attribute]
    submission_id = params[:submission_id]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    @submission = @ontology.explore.submissions({ display: "#{attribute},submissionId" }, submission_id)
    id = attribute_input_frame_id(acronym, submission_id, attribute)
    render_turbo_stream replace(id, partial: 'ontologies_metadata_curator/attribute_inline', locals: { id: id, attribute: attribute,
                                                                                                       submission: @submission, ontology: @ontology })
  end

  def edit

    if params[:selected_acronyms].nil? || params[:selected_metadata].nil?
      render_turbo_stream alert_error(id: 'application_modal_content') {'Select in the table submissions (rows) and metadata properties (columns) to start the bulk edit'}
      return
    end

    @selected_ontologies = params[:selected_acronyms].map { |x| ontology_and_submission_id(x) }
    @selected_metadata = params[:selected_metadata]
    @all_metadata = params[:all_metadata]
    render partial: 'ontologies_metadata_curator/form_edit'
  end

  def update
    @selected_ontologies = params[:selected_ontologies].map { |x| ontology_and_submission_id(x) }
    @active_ontology = ontology_and_submission_id(params[:active_ontology])
    @all_metadata = params[:all_metadata]&.split
    error_responses = []
    @submissions =  []
    active_submission_data = params['submission']["#{@active_ontology[0]}_#{@active_ontology[1]}"]

    @selected_ontologies.each do |onto, sub_i|
      new_data = active_submission_data
      new_data[:ontology] = onto
      new_data[:id] = sub_i
      error_responses << update_submission(new_data, sub_i) if new_data
      @submissions << @submission
    end

    errors = nil
    if error_responses.compact.any? { |x| x.status != 204 }
      errors = error_responses.map { |error_response| response_errors(error_response) }
    end
    respond_to do |format|
      format.turbo_stream do
        if errors
          render_turbo_stream(alert_error { errors.map { |e| e[:error] }.join(',') })
        else
          streams = [alert_success { 'Submissions were successfully updated' }]
          @submissions.each do |submission|
            submission.ontology = OpenStruct.new({acronym: submission.ontology})
            streams << replace("#{ontology_submission_id_label(submission.ontology.acronym, submission.submissionId)}_row", partial: 'ontologies_metadata_curator/metadata_table_row', locals: {submission: submission, attributes: @all_metadata })
          end
          render_turbo_stream(*streams)
        end
      end
    end
  end

  private


  def append_submission(ontology, submission)
    sub = submission
    return if sub.nil?

    sub.ontology = ontology
    @submissions << sub
  end

end

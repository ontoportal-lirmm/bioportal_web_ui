module OntologyUpdater
  extend ActiveSupport::Concern
  include SubmissionUpdater
  include TurboHelper

  def update_existent_ontology(acronym)
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    return nil if @ontology.nil?

    [@ontology, @ontology.update(values: ontology_params)]
  end

  def ontology_from_params
    ontology = LinkedData::Client::Models::Ontology.new(values: ontology_params)
    ontology.viewOf = nil unless ontology.isView
    ontology
  end

  def ontology_params
    return {} unless params[:ontology]

    p = params.require(:ontology).permit(:name, :acronym, { administeredBy: [] }, :viewingRestriction, { acl: [] },
                                         { hasDomain: [] }, :viewOf, :isView, :subscribe_notifications, { group: [] })

    p[:administeredBy].reject!(&:blank?) if p[:administeredBy]
    # p[:acl].reject!(&:blank?)
    p[:hasDomain].reject!(&:blank?) if p[:hasDomain]
    p[:group].reject!(&:blank?) if p[:group]
    p[:viewOf] = '' if p.key?(:viewOf) && !p.key?(:isView)
    p.to_h
  end

  def show_new_errors(object, redirection = 'ontologies/new')
    # TODO optimize
    @ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym', include_views: true, display_links: false, display_context: false)
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
    @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
    @errors = response_errors(object)
    @selected_attributes = (Array(errors_attributes) + Array(params[:submission]&.keys)).uniq
    @ontology = ontology_from_params

    @submission = submission_from_params(params[:submission]) if params[:submission]
    reset_agent_attributes
    if redirection.is_a?(Hash) && redirection[:id]
      render_turbo_stream replace(redirection[:id], partial: redirection[:partial])
    else
      render redirection, status: 422
    end
  end

  def errors_attributes
    @errors = @errors[:error] if @errors && @errors[:error]
    @errors.keys.map(&:to_s) if @errors.is_a?(Hash)
  end

  def new_submission_hash(ontology)
    @submission = ontology.explore.latest_submission({ display: 'all' })

    submission_params = submission_params(params[:submission])

    if @submission
      submission_params = submission_params(ActionController::Parameters.new(@submission.to_hash.delete_if do |k, v|
        v.nil? || v.respond_to?(:empty?) && v.empty?
      end.merge(submission_params)))
    end

    submission_params.delete 'submissionId'
    submission_params[:ontology] = @ontology.acronym
    ActionController::Parameters.new(submission_params)
  end

  def update_submission_hash(acronym)
    submission_params = submission_params(params[:submission])
    submission_params[:ontology] = acronym
    submission_params
  end

  private
  def reset_agent_attributes
    helpers.agent_attributes.each do |attr|
      current_val = @submission[attr]
      new_values = Array(current_val).map { |x| LinkedData::Client::Models::Agent.find(x) }

      new_values = new_values.first unless current_val.is_a?(Array)

      @submission[attr] = new_values
    end
  end
end

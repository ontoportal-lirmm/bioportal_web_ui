module OntologyUpdater
  extend ActiveSupport::Concern
  include SubmissionUpdater
  def ontology_from_params
    ontology = LinkedData::Client::Models::Ontology.new(values: ontology_params)
    ontology.viewOf = nil unless ontology.isView
    ontology
  end

  def save_ontology

    @ontology = save_new_ontology

    if response_error?(@ontology)
      show_new_errors(@ontology)
      return
    end


    @submission = save_new_submission(params[:submission], @ontology)

    if response_error?(@submission)
      @ontology.delete
      show_new_errors(@submission)
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  def add_ontology_submission(acronym)
    @ontology = update_existent_ontology(acronym)

    if @ontology.nil? || response_error?(@ontology)
      show_new_errors(@ontology)
      return
    end

    @submission = @ontology.explore.latest_submission({ display: 'all' })
    submission_params = submission_params(params[:submission])
    submission_params = submission_params(ActionController::Parameters.new(@submission.to_hash.delete_if { |k, v| v.nil? || v.respond_to?(:empty?) && v.empty? })).merge(submission_params) if @submission
    submission_params.delete 'submissionId'
    @submission = save_new_submission(ActionController::Parameters.new(submission_params), @ontology)

    if response_error?(@submission)
      show_new_errors(@submission)
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  def save_new_ontology
    ontology = ontology_from_params
    ontology.save
  end

  def update_existent_ontology(acronym)
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    return nil if @ontology.nil?

    @ontology.update_from_params(ontology_params)
  end

  def save_new_submission(submission_hash, ontology)
    new_submission_params = submission_hash
    new_submission_params[:ontology] = ontology.acronym
    save_submission(new_submission_params)
  end

  def ontology_params
    p = params.require(:ontology).permit(:name, :acronym, { administeredBy: [] }, :viewingRestriction, { acl: [] },
                                         { hasDomain: [] }, :viewOf,:isView, :subscribe_notifications, { group: [] })

    p[:administeredBy].reject!(&:blank?) if p[:administeredBy]
    # p[:acl].reject!(&:blank?)
    p[:hasDomain].reject!(&:blank?) if p[:hasDomain]
    p[:group].reject!(&:blank?)  if p[:group]
    p.to_h
  end

  def show_new_errors(object)
    # TODO optimize
    @ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym', include_views: true, display_links: false, display_context: false)
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
    @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
    @errors = response_errors(object)
    @ontology = ontology_from_params
    @submission  =  submission_from_params(params[:submission])
    render 'ontologies/new'
  end
end

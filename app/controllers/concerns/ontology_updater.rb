module OntologyUpdater
  extend ActiveSupport::Concern
  include SubmissionUpdater

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

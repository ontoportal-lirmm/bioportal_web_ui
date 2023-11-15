class OntologiesController < ApplicationController
  include MappingsHelper
  include FairScoreHelper
  include InstancesHelper
  include ActionView::Helpers::NumberHelper
  include OntologiesHelper
  include ConceptsHelper
  include SchemesHelper
  include CollectionsHelper
  include MappingStatistics
  include OntologyUpdater
  include TurboHelper
  include SubmissionFilter

  require 'multi_json'
  require 'cgi'

  helper :concepts
  helper :fair_score

  layout 'ontology'

  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]
  before_action :submission_metadata, only: [:show]
  KNOWN_PAGES = Set.new(["terms", "classes", "mappings", "notes", "widgets", "summary", "properties", "instances", "schemes", "collections"])
  EXTERNAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/ExternalMappings"
  INTERPORTAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/InterportalMappings"

  # GET /ontologies
  def index
    @categories = LinkedData::Client::Models::Category.all(display_links: false, display_context: false)
    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @filters = ontology_filters_init(@categories, @groups)
    init_filters(params)
    render 'ontologies/browser/browse'
  end

  def ontologies_filter
    @ontologies = submissions_paginate_filter(params)
    @object_count = count_objects(@ontologies)

    update_filters_counts = @object_count.map do |section, values_count|
      values_count.map do |value, count|
        replace("count_#{section}_#{value}") do
          helpers.turbo_frame_tag("count_#{section}_#{value}") do
            helpers.content_tag(:span, count.to_s, class: "hide-if-loading #{count.zero? ? 'disabled' : ''}")
          end
        end
      end
    end.flatten

    count_streams = [
      replace('ontologies_filter_count_request') do
        helpers.content_tag(:p, class: "browse-desc-text", style: "margin-bottom: 12px !important;") { "Showing #{@ontologies.size} of #{@analytics.keys.size}" }
      end
    ] + update_filters_counts

    streams =if params[:page].nil?
               [
                 prepend('ontologies_list_container', partial: 'ontologies/browser/ontologies'),
                 prepend('ontologies_list_container') {
                   helpers.turbo_frame_tag("ontologies_filter_count_request") do
                     helpers.browser_counter_loader
                   end
                 }
               ]
             else
               [replace("ontologies_list_view-page-1", partial: 'ontologies/browser/ontologies')]
             end

    render turbo_stream: streams + count_streams
  end

  def classes
    @submission = get_ontology_submission_ready(@ontology)
    get_class(params)

    if @submission.hasOntologyLanguage == 'SKOS'
      @schemes = get_schemes(@ontology)
      @collections = get_collections(@ontology, add_colors: true)
    else
      @instance_details, type = get_instance_and_type(params[:instanceid])
      unless @instance_details.empty? || type.nil? || concept_id_param_exist?(params)
        params[:conceptid] = type # set class id from the type of the specified instance id
      end
      @instances_concept_id = get_concept_id(params, @concept, @root)
    end

    if ['application/ld+json', 'application/json'].include?(request.accept)
      render plain: @concept.to_jsonld, content_type: request.accept and return
    end

    @current_purl = @concept.purl if $PURL_ENABLED

    unless @concept.nil? || @concept.id == 'bp_fake_root'
      @notes = @concept.explore.notes
    end

    if request.xhr?
      render 'ontologies/sections/visualize', layout: false
    else
      render 'ontologies/sections/visualize', layout: 'ontology_viewer'
    end
  end

  def properties
    @acronym = @ontology.acronym
    if request.xhr?
      return render 'ontologies/sections/properties', layout: false
    else
      return render 'ontologies/sections/properties', layout: 'ontology_viewer'
    end
  end

  def create
    @is_update_ontology = false
    @ontology = ontology_from_params.save

    if response_error?(@ontology)
      show_new_errors(@ontology)
      return
    end

    @submission = save_submission(new_submission_hash(@ontology))

    if response_error?(@submission)
      @ontology.delete
      show_new_errors(@submission)
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    redirect_to_home unless session[:user] && @ontology.administeredBy.include?(session[:user].id) || session[:user].admin?

    submission = @ontology.explore.latest_submission(include: 'submissionId')
    if submission
      redirect_to edit_ontology_submission_path(@ontology.acronym, submission.submissionId)
    else
      redirect_to new_ontology_submission_path(@ontology.acronym)
    end
  end

  def mappings
    @ontology_acronym = @ontology.acronym || params[:id]
    @mapping_counts = mapping_counts(@ontology_acronym)
    if request.xhr?
      render partial: 'ontologies/sections/mappings', layout: false
    else
      render partial: 'ontologies/sections/mappings', layout: 'ontology_viewer'
    end
  end

  def new
    @ontology = LinkedData::Client::Models::Ontology.new
    @submission = LinkedData::Client::Models::OntologySubmission.new
    @ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym', include_views: true, display_links: false, display_context: false)
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
    @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
  end

  def notes
    @notes = @ontology.explore.notes
    @notes_deletable = false
    # TODO_REV: Handle notes deletion
    # @notes.each {|n| @notes_deletable = true if n.deletable?(session[:user])} if @notes.kind_of?(Array)
    @note_link = "/ontologies/#{@ontology.acronym}/notes/"
    if request.xhr?
      render partial: 'ontologies/sections/notes', layout: false
    else
      render partial: 'ontologies/sections/notes', layout: 'ontology_viewer'
    end
  end

  def instances
    if request.xhr?
      render partial: 'instances/instances', locals: { id: 'instances-data-table' }, layout: false
    else
      render partial: 'instances/instances', locals: { id: 'instances-data-table' }, layout: 'ontology_viewer'
    end
  end

  def schemes
    @schemes = get_schemes(@ontology)
    scheme_id = params[:scheme_id] || @submission_latest.URI || nil
    @scheme = get_scheme(@ontology, scheme_id) if scheme_id

    if request.xhr?
      render partial: 'ontologies/sections/schemes', layout: false
    else
      render partial: 'ontologies/sections/schemes', layout: 'ontology_viewer'
    end
  end

  def collections
    @collections = get_collections(@ontology)
    collection_id = params[:collection_id]
    @collection = get_collection(@ontology, collection_id) if collection_id

    if request.xhr?
      render partial: 'ontologies/sections/collections', layout: false
    else
      render partial: 'ontologies/sections/collections', layout: 'ontology_viewer'
    end
  end

  # GET /ontologies/ACRONYM
  # GET /ontologies/1.xml
  def show

    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]

    # Hash to convert Lexvo URI to flag code

    # PURL-specific redirect to handle /ontologies/{ACR}/{CLASS_ID} paths
    if params[:purl_conceptid]
      params[:purl_conceptid] = 'root' if params[:purl_conceptid].eql?('classes')
      if params[:conceptid]
        params.delete(:purl_conceptid)
      else
        params[:conceptid] = params.delete(:purl_conceptid)
      end
      redirect_to "/ontologies/#{params[:acronym]}?p=classes#{params_string_for_redirect(params, prefix: "&")}", status: :moved_permanently
      return
    end

    if params[:ontology].to_i > 0
      acronym = BPIDResolver.id_to_acronym(params[:ontology])
      if acronym
        redirect_new_api
        return
      end
    end

    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    ontology_not_found(params[:ontology]) if @ontology.nil?

    # Handle the case where an ontology is converted to summary only.
    # See: https://github.com/ncbo/bioportal_web_ui/issues/133.
    if @ontology.summaryOnly && params[:p].present?
      pages = KNOWN_PAGES - ['summary', 'notes']
      if pages.include?(params[:p])
        redirect_to(ontology_path(params[:ontology]), status: :temporary_redirect) and return
      end
    end

    #@ob_instructions = helpers.ontolobridge_instructions_template(@ontology)

    # Get the latest submission (not necessarily the latest 'ready' submission)
    @submission_latest = @ontology.explore.latest_submission(include: 'all') rescue @ontology.explore.latest_submission(include: '')

    # Is the ontology downloadable?
    @ont_restricted = ontology_restricted?(@ontology.acronym)

    # Fix parameters to only use known pages
    params[:p] = nil unless KNOWN_PAGES.include?(params[:p])

    # This action is now a router using the 'p' parameter as the page to show
    case params[:p]
    when 'terms'
      params[:p] = 'classes'
      redirect_to "/ontologies/#{params[:ontology]}#{params_string_for_redirect(params)}", status: :moved_permanently
    when 'classes'
      self.classes #rescue self.summary
    when 'mappings'
      self.mappings #rescue self.summary
    when 'notes'
      self.notes #rescue self.summary
    when 'widgets'
      self.widgets #rescue self.summary
    when 'properties'
      self.properties #rescue self.summary
    when 'summary'
      self.summary
    when 'instances'
      self.instances
    when 'schemes'
      self.schemes
    when 'collections'
      self.collections
    else
      self.summary
    end

  end

  def submit_success
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    render 'submit_success'
  end

  # Main ontology description page (with metadata): /ontologies/ACRONYM
  def summary

    @metrics = @ontology.explore.metrics rescue []
    #@reviews = @ontology.explore.reviews.sort {|a,b| b.created <=> a.created} || []
    @projects = @ontology.explore.projects.sort { |a, b| a.name.downcase <=> b.name.downcase } || []
    @analytics = LinkedData::Client::HTTP.get(@ontology.links['analytics'])

    # Call to fairness assessment service
    tmp = fairness_service_enabled? ? get_fair_score(@ontology.acronym) : nil
    @fair_scores_data = create_fair_scores_data(tmp.values.first) unless tmp.nil?

    @views = get_views(@ontology)
    @view_decorators = @views.map { |view| ViewDecorator.new(view, view_context) }
    @ontology_relations_data = ontology_relations_data

    category_attributes = submission_metadata.group_by{|x| x['category']}.transform_values{|x| x.map{|attr| attr['attribute']} }
    @relations_array_display = @relations_array.map do |relation|
      attr = relation.split(':').last
      ["#{helpers.attr_label(attr, attr_metadata: helpers.attr_metadata(attr), show_tooltip: false)}(#{relation})",
       relation]
    end
    @methodology_properties = properties_hash_values(category_attributes["methodology"])
    @agents_properties = properties_hash_values(category_attributes["persons and organizations"])
    @dates_properties = properties_hash_values(category_attributes["dates"], custom_labels: {released: "Initially created On"})
    @links_properties = properties_hash_values(category_attributes["links"])
    @identifiers = properties_hash_values([:URI, :versionIRI, :identifier])
    @projects_properties = properties_hash_values(category_attributes["usage"])
    @ontology_icon_links = [%w[summary/download dataDump], %w[summary/homepage homepage], %w[summary/documentation documentation], %w[icons/github repository], %w[summary/sparql endpoint]]
    if request.xhr?
      render partial: 'ontologies/sections/metadata', layout: false
    else
      render partial: 'ontologies/sections/metadata', layout: 'ontology_viewer'
    end
  end


  def virtual
    redirect_new_api
  end

  def visualize
    redirect_new_api(true)
  end

  def widgets
    if request.xhr?
      render partial: 'ontologies/sections/widgets', layout: false
    else
      render partial: 'ontologies/sections/widgets', layout: 'ontology_viewer'
    end
  end
  

  def show_additional_metadata
    @metadata = submission_metadata
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    @submission_latest = @ontology.explore.latest_submission(include: 'all', display_context: false, display_links: false)
    render partial: 'ontologies/sections/additional_metadata'
  end

  def show_licenses

    @metadata = submission_metadata
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    @licenses= ["hasLicense","morePermissions","copyrightHolder"]
    @submission_latest = @ontology.explore.latest_submission(include: @licenses.join(","))
    render partial: 'ontologies/sections/licenses'
  end
  def ajax_ontologies


    render json: LinkedData::Client::Models::Ontology.all(include_views: true,
                                                          display: 'acronym,name', display_links: false, display_context: false)
  end

 

  def metrics_evolution
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    key = params[:metrics_key]
    ontology_not_found(params[:ontology_id]) if @ontology.nil?

    # Retrieve submissions in descending submissionId order (should be reverse chronological order)
    @submissions = @ontology.explore.submissions({ include: "metrics" })
                            .sort { |a, b| a.submissionId.to_i <=> b.submissionId.to_i  }.reverse || []

    metrics = @submissions.map { |s| s.metrics }

    data = {
      key => metrics.map { |m| m.nil? ? 0 : m[key] }
    }

    render partial: 'ontologies/sections/metadata/metrics_evolution_graph', locals: { data: data }
  end

  private
  def get_views(ontology)
    views = ontology.explore.views || []
    views.select!{ |view| view.access?(session[:user]) }
    views.sort{ |a,b| a.acronym.downcase <=> b.acronym.downcase }
  end

  def ontology_relations_data(sub = @submission_latest)
    ontology_relations_array = []
    @relations_array = ["omv:useImports", "door:isAlignedTo", "door:ontologyRelatedTo", "omv:isBackwardCompatibleWith", "omv:isIncompatibleWith", "door:comesFromTheSameDomain", "door:similarTo",
                        "door:explanationEvolution", "voaf:generalizes", "door:hasDisparateModelling", "dct:hasPart", "voaf:usedBy", "schema:workTranslation", "schema:translationOfWork"]

    return  if sub.nil?

    ont = sub.ontology
    # Get ontology relations between each other (ex: STY isAlignedTo GO)
    @relations_array.each do |relation_attr|
      relation_values = sub.send(relation_attr.to_s.split(':')[1])
      next if relation_values.nil? || relation_values.empty?

      relation_values = [relation_values] unless relation_values.kind_of?(Array)

      relation_values.each do |relation_value|
        next if relation_value.eql?(ont.acronym)

        target_id = relation_value
        target_in_portal = false
        # if we find our portal URL in the ontology URL, then we just keep the ACRONYM to try to get the ontology.
        relation_value = relation_value.split('/').last if relation_value.include?($UI_URL)

        # Use acronym to get ontology from the portal
        target_ont = LinkedData::Client::Models::Ontology.find_by_acronym(relation_value).first
        if target_ont
          target_id = target_ont.acronym
          target_in_portal = true
        end

        ontology_relations_array.push({ source: ont.acronym, target: target_id, relation: relation_attr.to_s, targetInPortal: target_in_portal })
      end
    end

    ontology_relations_array
  end
  def properties_hash_values(properties, sub: @submission_latest, custom_labels: {})
    return {} if sub.nil?

    properties.map { |x| [x.to_s, [sub.send(x.to_s), custom_labels[x.to_sym]]] }.to_h
  end

  def get_metrics_hash
    metrics_hash = {}
    # TODO: Metrics do not return for views on the backend, need to enable include_views param there
    @metrics = LinkedData::Client::Models::Metrics.all(include_views: true)
    @metrics.each {|m| metrics_hash[m.links['ontology']] = m }
    return metrics_hash
  end

  def determine_layout
    case action_name
    when 'index'
      'angular'
    else
      super
    end
  end

end

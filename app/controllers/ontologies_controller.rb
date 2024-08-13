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
  include SparqlHelper
  include SubmissionFilter
  include OntologyContentSerializer
  include UriRedirection
  include PropertiesHelper

  require "multi_json"
  require "cgi"

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
    @app_name = "FacetedBrowsing"
    @app_dir = "/browse"
    @base_path = @app_dir
    ontologies = LinkedData::Client::Models::Ontology.all(
      include: LinkedData::Client::Models::Ontology.include_params + ",viewOf", include_views: true, display_context: false,
    )
    ontologies_hash = Hash[ontologies.map { |o| [o.id, o] }]
    @admin = session[:user] ? session[:user].admin? : false
    @development = Rails.env.development?

    # We could get naturalLanguages, isOfType and formalityLevels from the API, but for performance we are storing it in config/bioportal_config_production.rb
    #@metadata = submission_metadata

    # The attributes used when retrieving the submission. We are not retrieving all attributes to be faster
    browse_attributes = 'ontology,acronym,submissionStatus,description,pullLocation,creationDate,released,name,naturalLanguage,hasOntologyLanguage,hasFormalityLevel,isOfType,contact'
    submissions = LinkedData::Client::Models::OntologySubmission.all(include_views: true, display_links: false,
display_context: false, include: browse_attributes)
    submissions_map = Hash[submissions.map {|sub| [sub.ontology.acronym, sub] }]

    @categories = LinkedData::Client::Models::Category.all(display_links: false, display_context: false)
    @categories_hash = Hash[@categories.map { |c| [c.id, c] }]

    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @groups_hash = Hash[@groups.map { |g| [g.id, g] }]

    analytics = LinkedData::Client::Analytics.last_month
    @analytics = Hash[analytics.onts.map { |o| [o[:ont].to_s, o[:views]] }]

  def ontologies_filter
    @time = Benchmark.realtime do
      @ontologies, @count, @count_objects, @request_params = submissions_paginate_filter(params)
    end

    metrics_hash = get_metrics_hash

    @formats = Set.new
    #get fairscores of all ontologies
    @fair_scores = fairness_service_enabled? ? get_fair_score("all") : nil

    @ontologies = []
    ontologies.each do |ont|
      o = {}

      if metrics_hash[ont.id]
        o[:class_count] = metrics_hash[ont.id].classes
        o[:individual_count] = metrics_hash[ont.id].individuals
      else
        o[:class_count] = 0
        o[:individual_count] = 0
      end
      o[:class_count_formatted] = number_with_delimiter(o[:class_count], delimiter: ",")
      o[:individual_count_formatted] = number_with_delimiter(o[:individual_count], delimiter: ",")

      o[:id] = ont.id
      o[:type] = ont.viewOf.nil? ? "ontology" : "ontology_view"
      o[:show] = ont.viewOf.nil? ? true : false # show ontologies only by default
      o[:reviews] = reviews[ont.id] || []
      o[:groups] = ont.group || []
      o[:categories] = ont.hasDomain || []
      o[:note_count] = ont.notes.length
      o[:review_count] = ont.reviews.length
      o[:project_count] = ont.projects.length
      o[:private] = ont.private?
      o[:popularity] = @analytics[ont.acronym] || 0
      o[:submissionStatus] = []
      o[:administeredBy] = ont.administeredBy
      o[:name] = ont.name
      o[:acronym] = ont.acronym
      o[:projects] = ont.projects
      o[:notes] = ont.notes

      if !@fair_scores.nil? && !@fair_scores[ont.acronym].nil?
        o[:fairScore] = @fair_scores[ont.acronym]["score"]
        o[:normalizedFairScore] = @fair_scores[ont.acronym]["normalizedScore"]
      else
        o[:fairScore] = nil
        o[:normalizedFairScore] = 0
      end

      if o[:type].eql?("ontology_view")
        unless ontologies_hash[ont.viewOf].blank?
          o[:viewOfOnt] = {
            name: ontologies_hash[ont.viewOf].name,
            acronym: ontologies_hash[ont.viewOf].acronym,
          }
        end
      end

      o[:artifacts] = []
      o[:artifacts] << "notes" if ont.notes.length > 0
      o[:artifacts] << "reviews" if ont.reviews.length > 0
      o[:artifacts] << "projects" if ont.projects.length > 0
      o[:artifacts] << "summary_only" if ont.summaryOnly

      sub = submissions_map[ont.acronym]
      if sub
        o[:submissionStatus] = sub.submissionStatus
        o[:submission] = true
        o[:pullLocation] = sub.pullLocation
        o[:description] = sub.description
        o[:creationDate] = sub.creationDate
        o[:released] = sub.released
        o[:naturalLanguage] = sub.naturalLanguage
        o[:hasFormalityLevel] = sub.hasFormalityLevel
        o[:isOfType] = sub.isOfType
        o[:submissionStatusFormatted] = submission_status2string(sub).gsub(/\(|\)/, "")

        o[:format] = sub.hasOntologyLanguage
        @formats << sub.hasOntologyLanguage
      else
        # Used to sort ontologies without submissions to the end when sorting on upload date
        o[:creationDate] = DateTime.parse("19900601")
      end

      @ontologies << o
    end

    @ontologies.sort! { |a, b| b[:popularity] <=> a[:popularity] }

    render "browse"
  end

  def classes
    @submission = get_ontology_submission_ready(@ontology)
    get_class(params)

    if @submission.hasOntologyLanguage == "SKOS"
      @schemes = get_schemes(@ontology)
      @collections = get_collections(@ontology, add_colors: true)
    else
      @instance_details, type = get_instance_and_type(params[:instanceid])
      unless @instance_details.empty? || type.nil? || concept_id_param_exist?(params)
        params[:conceptid] = type # set class id from the type of the specified instance id
      end
      @instances_concept_id = get_concept_id(params, @concept, @root)
    end

    if ["application/ld+json", "application/json"].include?(request.accept)
      render plain: @concept.to_jsonld, content_type: request.accept and return
    end

    @current_purl = @concept.purl if $PURL_ENABLED

    unless @concept.id == "bp_fake_root"
      @notes = @concept.explore.notes
    end

    if request.xhr?
      render "ontologies/sections/visualize", layout: false
    else
      render "ontologies/sections/visualize", layout: "ontology_viewer"
    end
  end

  def properties
    @acronym = @ontology.acronym
    @properties = LinkedData::Client::HTTP.get("/ontologies/#{@acronym}/properties/roots", { lang: request_lang })

    @property = get_property(@properties.first.id,  @acronym, include: 'all') unless @property || @properties.empty?

    if request.xhr?
      return render "ontologies/sections/properties", layout: false
    else
      return render "ontologies/sections/properties", layout: "ontology_viewer"
    end
  end

  def create
    if params[:commit].eql? "Cancel"
      redirect_to ontologies_path and return
    end

    @ontology = LinkedData::Client::Models::Ontology.new(values: ontology_params)
    @ontology_saved = @ontology.save
    if response_error?(@ontology_saved)
      @categories = LinkedData::Client::Models::Category.all
      @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
      @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
      @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
      @errors = response_errors(@ontology_saved)
      render "new"
    else
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    redirect_to_home unless session[:user] && @ontology.administeredBy.include?(session[:user].id) || session[:user].admin?
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
    @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
  end

  def mappings
    @ontology_acronym = @ontology.acronym || params[:id]
    @mapping_counts = mapping_counts(@ontology_acronym)
    @ontologies_mapping_count = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/ontologies")
    if request.xhr?
      render partial: "ontologies/sections/mappings", layout: false
    else
      render partial: "ontologies/sections/mappings", layout: "ontology_viewer"
    end
  end

  def new
    @ontology = LinkedData::Client::Models::Ontology.new
    @ontology.viewOf = params.dig(:ontology, :viewOf)
    @submission = LinkedData::Client::Models::OntologySubmission.new
    @submission.hasOntologyLanguage = 'OWL'
    @submission.released = Date.today.to_s
    @submission.status = 'production'
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
      render partial: "ontologies/sections/notes", layout: false
    else
      render partial: "ontologies/sections/notes", layout: "ontology_viewer"
    end
  end

  def instances
    if request.xhr?
      render partial: "instances/instances", locals: { id: "instances-data-table" }, layout: false
    else
      render partial: "instances/instances", locals: { id: "instances-data-table" }, layout: "ontology_viewer"
    end

    render partial: 'instances/instances', locals: { id: 'instances-data-table' }, layout: 'ontology_viewer'
  end

  def schemes
    @schemes = get_schemes(@ontology)
    scheme_id = params[:schemeid] || @submission_latest.URI || nil
    @scheme = get_scheme(@ontology, scheme_id) if scheme_id

    if request.xhr?
      render partial: "ontologies/sections/schemes", layout: false
    else
      render partial: "ontologies/sections/schemes", layout: "ontology_viewer"
    end
  end

  def collections
    @collections = get_collections(@ontology)
    collection_id = params[:collectionid]
    @collection = collection_id ? get_collection(@ontology, collection_id) : @collections.first

    render partial: 'ontologies/sections/collections', layout: 'ontology_viewer'
  end

  def sparql
    if request.xhr?
      render partial: "ontologies/sections/collections", layout: false
    else
      render partial: "ontologies/sections/collections", layout: "ontology_viewer"
    end
  end

  def content_serializer
    @result, _ = serialize_content(ontology_acronym: params[:acronym],
                      concept_id: params[:id],
                      format: params[:output_format])

    render 'ontologies/content_serializer', layout: nil
  end

  # GET /ontologies/ACRONYM
  # GET /ontologies/1.xml
  def show
    return redirect_to_file if redirect_to_file?

    # Hack to make ontologyid and conceptid work in addition to id and ontology params
    params[:id] = params[:id].nil? ? params[:ontologyid] : params[:id]
    params[:ontology] = params[:ontology].nil? ? params[:id] : params[:ontology]

    # Hash to convert Lexvo URI to flag code

    # PURL-specific redirect to handle /ontologies/{ACR}/{CLASS_ID} paths
    if params[:purl_conceptid]
      params[:purl_conceptid] = "root" if params[:purl_conceptid].eql?("classes")
      if params[:conceptid]
        params.delete(:purl_conceptid)
      else
        params[:conceptid] = params.delete(:purl_conceptid)
      end
      redirect_to "/ontologies/#{params[:acronym]}?p=classes&conceptid=#{params[:conceptid]}", status: :moved_permanently
      return
    end

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first

    if @ontology.nil? || @ontology.errors
      if ontology_access_denied?
        redirect_to "/login?redirect=/ontologies/#{params[:ontology]}", alert: t('login.private_ontology')
        return
      else
        ontology_not_found(params[:ontology])
      end
    end

    # Handle the case where an ontology is converted to summary only.
    # See: https://github.com/ncbo/bioportal_web_ui/issues/133.
    if @ontology.summaryOnly && params[:p].present?
      pages = KNOWN_PAGES - ["summary", "notes"]
      if pages.include?(params[:p])
        redirect_to(ontology_path(params[:ontology]), status: :temporary_redirect) and return
      end
    end

    #@ob_instructions = helpers.ontolobridge_instructions_template(@ontology)

    # Get the latest submission (not necessarily the latest 'ready' submission)
    @submission_latest = @ontology.explore.latest_submission rescue @ontology.explore.latest_submission(include: "")

    # Is the ontology downloadable?
    @ont_restricted = ontology_restricted?(@ontology.acronym)

    # Fix parameters to only use known pages
    params[:p] = nil unless KNOWN_PAGES.include?(params[:p])

    # This action is now a router using the 'p' parameter as the page to show
    case params[:p]
    when 'classes'
      self.classes # rescue self.summary
    when 'mappings'
      self.mappings # rescue self.summary
    when 'notes'
      self.notes # rescue self.summary
    when 'widgets'
      self.widgets # rescue self.summary
    when 'properties'
      self.properties # rescue self.summary
    when 'summary'
      self.summary
    when 'instances'
      self.instances
    when 'schemes'
      self.schemes
    when 'collections'
      self.collections
    when 'sparql'
      self.sparql
    else
      self.summary
    end
  end

  def submit_success
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    render "submit_success"
  end


  # Main ontology description page (with metadata): /ontologies/ACRONYM
  def summary
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first if @ontology.nil?
    ontology_not_found(params[:id]) if @ontology.nil?
    # Check to see if user is requesting json-ld, return the file from REST service if so

    if request.accept.to_s.eql?("application/ld+json") || request.accept.to_s.eql?("application/json")
      headers["Content-Type"] = request.accept.to_s
      render plain: @ontology.to_jsonld
      return
    end

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
    @relations_array_display = @relations_array.map do |relation|
      attr = relation.split(':').last
      ["#{helpers.attr_label(attr, attr_metadata: helpers.attr_metadata(attr), show_tooltip: false)}(#{relation})",
       relation]
    end
    @relations_array_display.unshift(['View of (bpm:viewOf)', 'bpm:viewOf'])

    category_attributes = submission_metadata.group_by { |x| x['category'] }.transform_values { |x| x.map { |attr| attr['attribute'] } }

    @config_properties = properties_hash_values(category_attributes["object description properties"])
    @methodology_properties = properties_hash_values(category_attributes["methodology"])
    @agents_properties = properties_hash_values(category_attributes["persons and organizations"])
    @dates_properties = properties_hash_values(category_attributes["dates"])
    @links_properties = properties_hash_values([:isFormatOf, :hasFormat, :source, :includedInDataCatalog])
    @content_properties = properties_hash_values(category_attributes["content"])
    @community_properties = properties_hash_values(category_attributes["community"] + [:notes])
    @identifiers = properties_hash_values([:URI, :versionIRI, :identifier])
    @identifiers["ontology_portal_uri"] = ["#{$UI_URL}/ontologies/#{@ontology.acronym}", "#{portal_name} URI"]
    @projects_properties = properties_hash_values(category_attributes["usage"] - ["hasDomain"])
    @ontology_icon_links = [%w[summary/download dataDump],
                            %w[summary/homepage homepage],
                            %w[summary/documentation documentation],
                            %w[icons/github repository],
                            %w[summary/sparql endpoint],
                            %w[icons/publication publication],
                            %w[icons/searching_database openSearchDescription]
    ]
    @ontology_icon_links.each do |icon|
      icon << helpers.attr_label(icon[1], attr_metadata: helpers.attr_metadata(icon[1]), show_tooltip: false)
    end
    if request.xhr?
      render partial: "ontologies/sections/metadata", layout: false
    else
      render partial: "ontologies/sections/metadata", layout: "ontology_viewer"
    end
  end

  def update
    if params["commit"] == "Cancel"
      acronym = params["id"]
      redirect_to "/ontologies/#{acronym}"
      return
    end
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology][:acronym] || params[:id]).first
    @ontology.update_from_params(ontology_params)
    error_response = @ontology.update
    if response_error?(error_response)
      @categories = LinkedData::Client::Models::Category.all
      @user_select_list = LinkedData::Client::Models::User.all.map { |u| [u.username, u.id] }
      @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
      @errors = response_errors(error_response)
      @errors = { acronym: "Acronym already exists, please use another" } if error_response.status == 409
      flash[:error] = @errors
      redirect_to "/ontologies/#{@ontology.acronym}/edit"
    else
      user = LinkedData::Client::Models::User.find(session[:user].id)
      subscribed = helpers.subscribed_to_ontology?(ontology_acronym, user)
      link = "javascript:void(0);"
      user_id = user.id
    end
    count = helpers.count_subscriptions(params[:ontology_id])
    render inline: helpers.turbo_frame_tag('subscribe_button') {
      render_to_string(OntologySubscribeButtonComponent.new(id: '', ontology_id: ontology_id, subscribed: subscribed, user_id: user_id, count: count, link: link), layout: nil)
    }
  end

  def widgets
    if request.xhr?
      render partial: "ontologies/sections/widgets", layout: false
    else
      render partial: "ontologies/sections/widgets", layout: "ontology_viewer"
    end
  end

  private

  def ontology_params
    p = params.require(:ontology).permit(:name, :acronym, { administeredBy: [] }, :viewingRestriction, { acl: [] },
                                         { hasDomain: [] }, :isView, :viewOf, :subscribe_notifications, { group: [] })

    p[:administeredBy].reject!(&:blank?)
    p[:acl].reject!(&:blank?)
    p[:hasDomain].reject!(&:blank?)
    p[:group].reject!(&:blank?)
    p.to_h
  end

  def ontology_relations_data(sub = @submission_latest)
    ontology_relations_array = []
    @relations_array = ["bpm:viewOf", "omv:useImports", "door:isAlignedTo", "door:ontologyRelatedTo", "omv:isBackwardCompatibleWith", "omv:isIncompatibleWith", "door:comesFromTheSameDomain", "door:similarTo",
                        "door:explanationEvolution", "voaf:generalizes", "door:hasDisparateModelling", "dct:hasPart", "voaf:usedBy", "schema:workTranslation", "schema:translationOfWork"]

    return if sub.nil?

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
        target_ont = nil
        # if we find our portal URL in the ontology URL, then we just keep the ACRONYM to try to get the ontology.
        if relation_value.include?(helpers.portal_name.downcase)
          relation_value = relation_value.split('/').last
          target_ont = LinkedData::Client::Models::Ontology.find_by_acronym(relation_value).first
        end

        # Use acronym to get ontology from the portal
        if target_ont
          target_id = target_ont.acronym
          target_in_portal = true
        end

        ontology_relations_array.push({ source: ont.acronym, target: target_id, relation: relation_attr.to_s, targetInPortal: target_in_portal })
      end
    end

    if ont.viewOf
      target_ont = LinkedData::Client::Models::Ontology.find(ont.viewOf)
      ontology_relations_array.push({ source: ont.acronym, target: target_ont.acronym, relation: "bpm:viewOf", targetInPortal: true })
    end

    ontology_relations_array
  end

  def properties_hash_values(properties, sub: @submission_latest, custom_labels: {})
    return {} if sub.nil?

    properties.map { |x| [x.to_s, [sub.send(x.to_s), custom_labels[x.to_sym]]] }.to_h
  end


  def determine_layout
    case action_name
    when "index"
      "angular"
    else
      super
    end
  end

  def get_views(ontology)
    views = ontology.explore.views || []
    views.select! { |view| view.access?(session[:user]) }
    views.sort { |a, b| a.acronym.downcase <=> b.acronym.downcase }
  end
end

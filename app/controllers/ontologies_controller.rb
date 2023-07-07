class OntologiesController < ApplicationController
  include MappingsHelper
  include FairScoreHelper
  include InstancesHelper
  include ActionView::Helpers::NumberHelper
  include OntologiesHelper
  include SchemesHelper
  include CollectionsHelper
  include MappingStatistics

  require 'multi_json'
  require 'cgi'

  helper :concepts
  helper :fair_score

  layout :determine_layout

  before_action :authorize_and_redirect, :only=>[:edit,:update,:create,:new]
  before_action :submission_metadata, only: [:show]
  KNOWN_PAGES = Set.new(["terms", "classes", "mappings", "notes", "widgets", "summary", "properties" ,"instances", "schemes", "collections"])
  EXTERNAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/ExternalMappings"
  INTERPORTAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/InterportalMappings"


  # GET /ontologies
  def index
    @app_name = 'FacetedBrowsing'
    @app_dir = '/browse'
    @base_path = @app_dir
    ontologies = LinkedData::Client::Models::Ontology.all(include: LinkedData::Client::Models::Ontology.include_params + ',viewOf', include_views: true, display_context: false)
    ontologies_hash = Hash[ontologies.map {|o| [o.id, o] }]
    @admin = session[:user] ? session[:user].admin? : false
    @development = Rails.env.development?

    # We could get naturalLanguages, isOfType and formalityLevels from the API, but for performance we are storing it in config/bioportal_config_production.rb
    #@metadata = submission_metadata

    # The attributes used when retrieving the submission. We are not retrieving all attributes to be faster
    browse_attributes = 'ontology,acronym,submissionStatus,description,pullLocation,creationDate,released,name,naturalLanguage,hasOntologyLanguage,hasFormalityLevel,isOfType,contact'
    submissions = LinkedData::Client::Models::OntologySubmission.all(include_views: true, display_links: false,display_context: false, include: browse_attributes)
    submissions_map = Hash[submissions.map {|sub| [sub.ontology.acronym, sub] }]

    @categories = LinkedData::Client::Models::Category.all(display_links: false, display_context: false)
    @categories_hash = Hash[@categories.map {|c| [c.id, c] }]

    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @groups_hash = Hash[@groups.map {|g| [g.id, g] }]

    analytics = LinkedData::Client::Analytics.last_month
    @analytics = Hash[analytics.onts.map {|o| [o[:ont].to_s, o[:views]]}]

    reviews = {}
    LinkedData::Client::Models::Review.all(display_links: false, display_context: false).each do |r|
      reviews[r.reviewedOntology] ||= []
      reviews[r.reviewedOntology] << r
    end

    metrics_hash = get_metrics_hash

    @formats = Set.new
    #get fairscores of all ontologies
    @fair_scores = fairness_service_enabled? ? get_fair_score('all') : nil;

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
      o[:class_count_formatted] = number_with_delimiter(o[:class_count], delimiter: ',')
      o[:individual_count_formatted] = number_with_delimiter(o[:individual_count], delimiter: ',')

      o[:id]               = ont.id
      o[:type]             = ont.viewOf.nil? ? 'ontology' : 'ontology_view'
      o[:show]             = ont.viewOf.nil? ? true : false # show ontologies only by default
      o[:reviews]          = reviews[ont.id] || []
      o[:groups]           = ont.group || []
      o[:categories]       = ont.hasDomain || []
      o[:note_count]       = ont.notes.length
      o[:review_count]     = ont.reviews.length
      o[:project_count]    = ont.projects.length
      o[:private]          = ont.private?
      o[:popularity]       = @analytics[ont.acronym] || 0
      o[:submissionStatus] = []
      o[:administeredBy]   = ont.administeredBy
      o[:name]             = ont.name
      o[:acronym]          = ont.acronym
      o[:projects]         = ont.projects
      o[:notes]            = ont.notes

      if !@fair_scores.nil? && !@fair_scores[ont.acronym].nil?
        o[:fairScore]            = @fair_scores[ont.acronym]['score']
        o[:normalizedFairScore]  = @fair_scores[ont.acronym]['normalizedScore']
      else
        o[:fairScore]            = nil
        o[:normalizedFairScore]  = 0
      end

      if o[:type].eql?('ontology_view')
        unless ontologies_hash[ont.viewOf].blank?
          o[:viewOfOnt] = {
            name: ontologies_hash[ont.viewOf].name,
            acronym: ontologies_hash[ont.viewOf].acronym
          }
        end
      end

      o[:artifacts] = []
      o[:artifacts] << 'notes' if ont.notes.length > 0
      o[:artifacts] << 'reviews' if ont.reviews.length > 0
      o[:artifacts] << 'projects' if ont.projects.length > 0
      o[:artifacts] << 'summary_only' if ont.summaryOnly

      sub = submissions_map[ont.acronym]
      if sub
        o[:submissionStatus]          = sub.submissionStatus
        o[:submission]                = true
        o[:pullLocation]              = sub.pullLocation
        o[:description]               = sub.description
        o[:creationDate]              = sub.creationDate
        o[:released]                  = sub.released
        o[:naturalLanguage]           = sub.naturalLanguage
        o[:hasFormalityLevel]         = sub.hasFormalityLevel
        o[:isOfType]                  = sub.isOfType
        o[:submissionStatusFormatted] = submission_status2string(sub).gsub(/\(|\)/, '')

        o[:format] = sub.hasOntologyLanguage
        @formats << sub.hasOntologyLanguage
      else
        # Used to sort ontologies without submissions to the end when sorting on upload date
        o[:creationDate] = DateTime.parse('19900601')
      end

      @ontologies << o
    end

    @ontologies.sort! {|a,b| b[:popularity] <=> a[:popularity]}


    render 'browse'
  end

  def classes
    @submission = get_ontology_submission_ready(@ontology)
    get_class(params)

    if @submission.hasOntologyLanguage == 'SKOS'
      @schemes =  get_schemes(@ontology)
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

    unless @concept.id == 'bp_fake_root'
      @notes = @concept.explore.notes
    end

    update_tab(@ontology, @concept.id)

    if request.xhr?
      render 'ontologies/sections/visualize', layout: false
    else
      render 'ontologies/sections/visualize', layout: 'ontology_viewer'
    end
  end

  def properties
    if request.xhr?
      return render 'ontologies/sections/properties', layout: false
    else
      return render 'ontologies/sections/properties', layout: 'ontology_viewer'
    end
  end

  def create
    if params[:commit].eql? 'Cancel'
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
      render 'new'
    else
      if @ontology_saved.summaryOnly
        redirect_to "/ontologies/success/#{@ontology.acronym}"
      else
        redirect_to new_ontology_submission_path(@ontology.acronym)
      end
    end
  end

  def edit
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    redirect_to_home unless session[:user] && @ontology.administeredBy.include?(session[:user].id) || session[:user].admin?
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
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
    @ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym', include_views: true,display_links: false, display_context: false)
    @categories = LinkedData::Client::Models::Category.all
    @groups = LinkedData::Client::Models::Group.all
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
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
      render partial: 'instances/instances', locals: { id: 'instances-data-table'}, layout: false
    else
      render partial: 'instances/instances', locals: { id: 'instances-data-table'}, layout: 'ontology_viewer'
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
    $LEXVO_TO_FLAG = { 'http://lexvo.org/id/iso639-3/aar' => 'aa', 'http://lexvo.org/id/iso639-3/abk' => 'ab',
                       'http://lexvo.org/id/iso639-3/ave' => 'ae', 'http://lexvo.org/id/iso639-3/afr' => 'af',
                       'http://lexvo.org/id/iso639-3/aka' => 'ak', 'http://lexvo.org/id/iso639-3/amh' => 'am',
                       'http://lexvo.org/id/iso639-3/arg' => 'an', 'http://lexvo.org/id/iso639-3/ara' => 'ar', 'http://lexvo.org/id/iso639-3/asm' => 'as', 'http://lexvo.org/id/iso639-3/ava' => 'av', 'http://lexvo.org/id/iso639-3/aym' => 'ay', 'http://lexvo.org/id/iso639-3/aze' => 'az', 'http://lexvo.org/id/iso639-3/bak' => 'ba', 'http://lexvo.org/id/iso639-3/bel' => 'be', 'http://lexvo.org/id/iso639-3/bul' => 'bg', 'http://lexvo.org/id/iso639-3/bis' => 'bi', 'http://lexvo.org/id/iso639-3/bam' => 'bm', 'http://lexvo.org/id/iso639-3/ben' => 'bn', 'http://lexvo.org/id/iso639-3/bod' => 'bo', 'http://lexvo.org/id/iso639-3/bre' => 'br', 'http://lexvo.org/id/iso639-3/bos' => 'bs', 'http://lexvo.org/id/iso639-3/cat' => 'ca', 'http://lexvo.org/id/iso639-3/che' => 'ce', 'http://lexvo.org/id/iso639-3/cha' => 'ch', 'http://lexvo.org/id/iso639-3/cos' => 'co', 'http://lexvo.org/id/iso639-3/cre' => 'cr', 'http://lexvo.org/id/iso639-3/ces' => 'cs', 'http://lexvo.org/id/iso639-3/chu' => 'cu', 'http://lexvo.org/id/iso639-3/chv' => 'cv', 'http://lexvo.org/id/iso639-3/cym' => 'cy', 'http://lexvo.org/id/iso639-3/dan' => 'da', 'http://lexvo.org/id/iso639-3/deu' => 'de', 'http://lexvo.org/id/iso639-3/div' => 'dv', 'http://lexvo.org/id/iso639-3/dzo' => 'dz', 'http://lexvo.org/id/iso639-3/ewe' => 'ee', 'http://lexvo.org/id/iso639-3/ell' => 'el', 'http://lexvo.org/id/iso639-3/eng' => 'en', 'http://lexvo.org/id/iso639-3/epo' => 'eo', 'http://lexvo.org/id/iso639-3/spa' => 'es', 'http://lexvo.org/id/iso639-3/est' => 'et', 'http://lexvo.org/id/iso639-3/eus' => 'eu', 'http://lexvo.org/id/iso639-3/fas' => 'fa', 'http://lexvo.org/id/iso639-3/ful' => 'ff', 'http://lexvo.org/id/iso639-3/fin' => 'fi', 'http://lexvo.org/id/iso639-3/fij' => 'fj', 'http://lexvo.org/id/iso639-3/fao' => 'fo', 'http://lexvo.org/id/iso639-3/fra' => 'fr', 'http://lexvo.org/id/iso639-3/fry' => 'fy', 'http://lexvo.org/id/iso639-3/gle' => 'ga', 'http://lexvo.org/id/iso639-3/gla' => 'gd', 'http://lexvo.org/id/iso639-3/glg' => 'gl', 'http://lexvo.org/id/iso639-3/grn' => 'gn', 'http://lexvo.org/id/iso639-3/guj' => 'gu', 'http://lexvo.org/id/iso639-3/glv' => 'gv', 'http://lexvo.org/id/iso639-3/hau' => 'ha', 'http://lexvo.org/id/iso639-3/heb' => 'he', 'http://lexvo.org/id/iso639-3/hin' => 'hi', 'http://lexvo.org/id/iso639-3/hmo' => 'ho', 'http://lexvo.org/id/iso639-3/hrv' => 'hr', 'http://lexvo.org/id/iso639-3/hat' => 'ht', 'http://lexvo.org/id/iso639-3/hun' => 'hu', 'http://lexvo.org/id/iso639-3/hye' => 'hy', 'http://lexvo.org/id/iso639-3/her' => 'hz', 'http://lexvo.org/id/iso639-3/ina' => 'ia', 'http://lexvo.org/id/iso639-3/ind' => 'id', 'http://lexvo.org/id/iso639-3/ile' => 'ie', 'http://lexvo.org/id/iso639-3/ibo' => 'ig', 'http://lexvo.org/id/iso639-3/iii' => 'ii', 'http://lexvo.org/id/iso639-3/ipk' => 'ik', 'http://lexvo.org/id/iso639-3/ido' => 'io', 'http://lexvo.org/id/iso639-3/isl' => 'is', 'http://lexvo.org/id/iso639-3/ita' => 'it', 'http://lexvo.org/id/iso639-3/iku' => 'iu', 'http://lexvo.org/id/iso639-3/jpn' => 'ja', 'http://lexvo.org/id/iso639-3/jav' => 'jv', 'http://lexvo.org/id/iso639-3/kat' => 'ka', 'http://lexvo.org/id/iso639-3/kon' => 'kg', 'http://lexvo.org/id/iso639-3/kik' => 'ki', 'http://lexvo.org/id/iso639-3/kua' => 'kj', 'http://lexvo.org/id/iso639-3/kaz' => 'kk', 'http://lexvo.org/id/iso639-3/kal' => 'kl', 'http://lexvo.org/id/iso639-3/khm' => 'km', 'http://lexvo.org/id/iso639-3/kan' => 'kn', 'http://lexvo.org/id/iso639-3/kor' => 'ko', 'http://lexvo.org/id/iso639-3/kau' => 'kr', 'http://lexvo.org/id/iso639-3/kas' => 'ks', 'http://lexvo.org/id/iso639-3/kur' => 'ku', 'http://lexvo.org/id/iso639-3/kom' => 'kv', 'http://lexvo.org/id/iso639-3/cor' => 'kw', 'http://lexvo.org/id/iso639-3/kir' => 'ky', 'http://lexvo.org/id/iso639-3/lat' => 'la', 'http://lexvo.org/id/iso639-3/ltz' => 'lb', 'http://lexvo.org/id/iso639-3/lug' => 'lg', 'http://lexvo.org/id/iso639-3/lim' => 'li', 'http://lexvo.org/id/iso639-3/lin' => 'ln', 'http://lexvo.org/id/iso639-3/lao' => 'lo', 'http://lexvo.org/id/iso639-3/lit' => 'lt', 'http://lexvo.org/id/iso639-3/lub' => 'lu', 'http://lexvo.org/id/iso639-3/lav' => 'lv', 'http://lexvo.org/id/iso639-3/mlg' => 'mg', 'http://lexvo.org/id/iso639-3/mah' => 'mh', 'http://lexvo.org/id/iso639-3/mri' => 'mi', 'http://lexvo.org/id/iso639-3/mkd' => 'mk', 'http://lexvo.org/id/iso639-3/mal' => 'ml', 'http://lexvo.org/id/iso639-3/mon' => 'mn', 'http://lexvo.org/id/iso639-3/mar' => 'mr', 'http://lexvo.org/id/iso639-3/msa' => 'ms', 'http://lexvo.org/id/iso639-3/mlt' => 'mt', 'http://lexvo.org/id/iso639-3/mya' => 'my', 'http://lexvo.org/id/iso639-3/nau' => 'na', 'http://lexvo.org/id/iso639-3/nob' => 'nb', 'http://lexvo.org/id/iso639-3/nde' => 'nd', 'http://lexvo.org/id/iso639-3/nep' => 'ne', 'http://lexvo.org/id/iso639-3/ndo' => 'ng', 'http://lexvo.org/id/iso639-3/nld' => 'nl', 'http://lexvo.org/id/iso639-3/nno' => 'nn', 'http://lexvo.org/id/iso639-3/nor' => 'no', 'http://lexvo.org/id/iso639-3/nbl' => 'nr', 'http://lexvo.org/id/iso639-3/nav' => 'nv', 'http://lexvo.org/id/iso639-3/nya' => 'ny', 'http://lexvo.org/id/iso639-3/oci' => 'oc', 'http://lexvo.org/id/iso639-3/oji' => 'oj', 'http://lexvo.org/id/iso639-3/orm' => 'om', 'http://lexvo.org/id/iso639-3/ori' => 'or', 'http://lexvo.org/id/iso639-3/oss' => 'os', 'http://lexvo.org/id/iso639-3/pan' => 'pa', 'http://lexvo.org/id/iso639-3/pli' => 'pi', 'http://lexvo.org/id/iso639-3/pol' => 'pl', 'http://lexvo.org/id/iso639-3/pus' => 'ps', 'http://lexvo.org/id/iso639-3/por' => 'pt', 'http://lexvo.org/id/iso639-3/que' => 'qu', 'http://lexvo.org/id/iso639-3/roh' => 'rm', 'http://lexvo.org/id/iso639-3/run' => 'rn', 'http://lexvo.org/id/iso639-3/ron' => 'ro', 'http://lexvo.org/id/iso639-3/rus' => 'ru', 'http://lexvo.org/id/iso639-3/kin' => 'rw', 'http://lexvo.org/id/iso639-3/san' => 'sa', 'http://lexvo.org/id/iso639-3/srd' => 'sc', 'http://lexvo.org/id/iso639-3/snd' => 'sd', 'http://lexvo.org/id/iso639-3/sme' => 'se', 'http://lexvo.org/id/iso639-3/sag' => 'sg', 'http://lexvo.org/id/iso639-3/hbs' => 'sh', 'http://lexvo.org/id/iso639-3/sin' => 'si', 'http://lexvo.org/id/iso639-3/slk' => 'sk', 'http://lexvo.org/id/iso639-3/slv' => 'sl', 'http://lexvo.org/id/iso639-3/smo' => 'sm', 'http://lexvo.org/id/iso639-3/sna' => 'sn', 'http://lexvo.org/id/iso639-3/som' => 'so', 'http://lexvo.org/id/iso639-3/sqi' => 'sq', 'http://lexvo.org/id/iso639-3/srp' => 'sr', 'http://lexvo.org/id/iso639-3/ssw' => 'ss', 'http://lexvo.org/id/iso639-3/sot' => 'st', 'http://lexvo.org/id/iso639-3/sun' => 'su', 'http://lexvo.org/id/iso639-3/swe' => 'sv', 'http://lexvo.org/id/iso639-3/swa' => 'sw', 'http://lexvo.org/id/iso639-3/tam' => 'ta', 'http://lexvo.org/id/iso639-3/tel' => 'te', 'http://lexvo.org/id/iso639-3/tgk' => 'tg', 'http://lexvo.org/id/iso639-3/tha' => 'th', 'http://lexvo.org/id/iso639-3/tir' => 'ti', 'http://lexvo.org/id/iso639-3/tuk' => 'tk', 'http://lexvo.org/id/iso639-3/tgl' => 'tl', 'http://lexvo.org/id/iso639-3/tsn' => 'tn', 'http://lexvo.org/id/iso639-3/ton' => 'to', 'http://lexvo.org/id/iso639-3/tur' => 'tr', 'http://lexvo.org/id/iso639-3/tso' => 'ts', 'http://lexvo.org/id/iso639-3/tat' => 'tt', 'http://lexvo.org/id/iso639-3/twi' => 'tw', 'http://lexvo.org/id/iso639-3/tah' => 'ty', 'http://lexvo.org/id/iso639-3/uig' => 'ug', 'http://lexvo.org/id/iso639-3/ukr' => 'uk', 'http://lexvo.org/id/iso639-3/urd' => 'ur', 'http://lexvo.org/id/iso639-3/uzb' => 'uz', 'http://lexvo.org/id/iso639-3/ven' => 've', 'http://lexvo.org/id/iso639-3/vie' => 'vi', 'http://lexvo.org/id/iso639-3/vol' => 'vo', 'http://lexvo.org/id/iso639-3/wln' => 'wa', 'http://lexvo.org/id/iso639-3/wol' => 'wo', 'http://lexvo.org/id/iso639-3/xho' => 'xh', 'http://lexvo.org/id/iso639-3/yid' => 'yi', 'http://lexvo.org/id/iso639-3/yor' => 'yo', 'http://lexvo.org/id/iso639-3/zha' => 'za', 'http://lexvo.org/id/iso639-3/zho' => 'zh', 'http://lexvo.org/id/iso639-3/zul' => 'zu' }

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
    @submission_latest = @ontology.explore.latest_submission rescue @ontology.explore.latest_submission(include: '')
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
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first if @ontology.nil?
    ontology_not_found(params[:id]) if @ontology.nil?
    # Check to see if user is requesting json-ld, return the file from REST service if so

    if request.accept.to_s.eql?('application/ld+json') || request.accept.to_s.eql?('application/json')
      headers['Content-Type'] = request.accept.to_s
      render plain: @ontology.to_jsonld
      return
    end

    @metrics = @ontology.explore.metrics rescue []
    #@reviews = @ontology.explore.reviews.sort {|a,b| b.created <=> a.created} || []
    @projects = @ontology.explore.projects.sort {|a,b| a.name.downcase <=> b.name.downcase } || []
    @analytics = LinkedData::Client::HTTP.get(@ontology.links['analytics'])

    #Call to fairness assessment service
    tmp = fairness_service_enabled? ? get_fair_score(@ontology.acronym) : nil
    @fair_scores_data = create_fair_scores_data(tmp.values.first) unless tmp.nil?

    @views = get_views(@ontology)
    @view_decorators = @views.map{ |view| ViewDecorator.new(view, view_context) }

    if request.xhr?
      render partial: 'ontologies/sections/metadata', layout: false
    else
      render partial: 'ontologies/sections/metadata', layout: 'ontology_viewer'
    end
  end

  def update
    if params['commit'] == 'Cancel'
      acronym = params['id']
      redirect_to "/ontologies/#{acronym}"
      return
    end
    # Note: find_by_acronym includes ontology views
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology][:acronym] || params[:id]).first
    @ontology.update_from_params(ontology_params)
    @ontology.viewOf = nil if @ontology.isView.eql? "0"
    error_response = @ontology.update
    if response_error?(error_response)
      @categories = LinkedData::Client::Models::Category.all
      @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
      @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
      @errors = response_errors(error_response)
      @errors = { acronym: 'Acronym already exists, please use another' } if error_response.status == 409
      flash[:error] = @errors
      redirect_to "/ontologies/#{@ontology.acronym}/edit"
    else
      # TODO_REV: Enable subscriptions
      # if params["ontology"]["subscribe_notifications"].eql?("1")
      #  DataAccess.createUserSubscriptions(@ontology.administeredBy, @ontology.ontologyId, NOTIFICATION_TYPES[:all])
      # end
      redirect_to "/ontologies/#{@ontology.acronym}"
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
  def ajax_ontologies
   
    
    render json: LinkedData::Client::Models::Ontology.all(include_views: true,
       display: 'acronym,name', display_links: false, display_context: false)
  end
  private





  def ontology_params
    p = params.require(:ontology).permit(:name, :acronym, { administeredBy:[] }, :viewingRestriction, { acl:[] },
                                         { hasDomain:[] }, :isView, :viewOf, :subscribe_notifications, {group:[]})

    p[:administeredBy].reject!(&:blank?)
    p[:acl].reject!(&:blank?)
    p[:hasDomain].reject!(&:blank?)
    p[:group].reject!(&:blank?)
    p.to_h
  end

  def determine_layout
    case action_name
    when 'index'
      'angular'
    else
      super
    end
  end

  def get_views(ontology)
    views = ontology.explore.views || []
    views.select!{ |view| view.access?(session[:user]) }
    views.sort{ |a,b| a.acronym.downcase <=> b.acronym.downcase }
  end

end

module SubmissionFilter
  extend ActiveSupport::Concern

  BROWSE_ATTRIBUTES = ['ontology', 'submissionStatus', 'description', 'pullLocation', 'creationDate',
                       'contact', 'released', 'naturalLanguage', 'hasOntologyLanguage',
                       'hasFormalityLevel', 'isOfType', 'deprecated', 'status', 'metrics']

  def init_filters(params)
    @show_views = params[:show_views]&.eql?('true')
    @show_private_only = params[:private_only]&.eql?('true')
    @show_retired = params[:show_retired]&.eql?('true')
    @selected_format = params[:format]
    @selected_sort_by = params[:sort_by]
    @search = params[:search]
  end

  def submissions_paginate_filter(params)
    request_params = filters_params(params, page: params[:page] || 1)
    init_filters(params)
    @page = LinkedData::Client::Models::OntologySubmission.all(request_params)

    submissions = @page.collection

    # analytics = LinkedData::Client::Analytics.last_month
    # @analytics = Hash[analytics.onts.map { |o| [o[:ont].to_s, o[:views]] }]

    # get fair scores of all ontologies
    @fair_scores = fairness_service_enabled? ? get_fair_score('all') : nil
    submissions.reject{|sub| sub.ontology.nil?}.map { |sub| ontology_hash(sub) }
  end

  def ontologies_filter_url(filters, page: 1, count: false)
    helpers.ontologies_filter_url(filters, page: page, count: count)
  end

  private

  def filters_params(params, includes: BROWSE_ATTRIBUTES.join(','), page: 1, pagesize: 5)
    request_params = { display_links: false, display_context: false,
                       include: includes, include_status: 'RDF' }
    request_params.merge!(page: page, pagesize: pagesize) if page
    params[:sort_by] ||= 'ontology_name'
    filters_values_map = {
      categories: :hasDomain,
      groups: :group,
      naturalLanguage: :naturalLanguage,
      isOfType: :isOfType,
      format: :hasOntologyLanguage,
      hasFormalityLevel: :hasFormalityLevel,
      search: %i[name acronym],
      sort_by: :order_by
    }

    filters_boolean_map = {
      show_views: { api_key: :also_include_views, default: 'true' },
      private_only: { api_key: :viewingRestriction, default: 'private' },
      show_retired: { api_key: :status, default: 'retired' }
    }
    @filters = {}

    filters_boolean_map.each do |k, v|
      next unless params[k].eql?('true') || params[k].eql?(v[:default])

      @filters.merge!(k => v[:default])
      request_params.merge!(v[:api_key] => v[:default])
    end

    filters_values_map.each do |filter, api_key|
      next if params[filter].nil? || params[filter].empty?

      @filters.merge!(filter => params[filter])
      Array(api_key).each do |key|
        request_params.merge!(key => params[filter])
      end
    end
    @show_views = params[:show_views]&.eql?('true')
    @show_private_only = params[:private_only]&.eql?('true')
    @show_retired = params[:show_retired]&.eql?('true')
    @selected_format = params[:format]
    @search = params[:search]

    request_params
  end

  def ontology_hash(sub)
    o = {}
    ont = sub.ontology

    add_ontology_attributes(o, ont)
    add_submission_attributes(o, sub)
    add_fair_score_metrics(o, ont)

    if sub.metrics
      o[:class_count] = sub.metrics.classes
      o[:individual_count] = sub.metrics.individuals
    else
      o[:class_count] = 0
      o[:individual_count] = 0
    end
    o[:class_count_formatted] = number_with_delimiter(o[:class_count], delimiter: ',')
    o[:individual_count_formatted] = number_with_delimiter(o[:individual_count], delimiter: ',')

    o[:note_count] = ont.notes.length
    o[:project_count] = ont.projects.length
    # o[:popularity] = @analytics[ont.acronym] || 0

    # if o[:type].eql?('ontology_view')
    #   unless ontologies_hash[ont.viewOf].blank?
    #     o[:viewOfOnt] = {
    #       name: ontologies_hash[ont.viewOf].name,
    #       acronym: ontologies_hash[ont.viewOf].acronym
    #     }
    #   end
    # end

    o
  end

  def add_submission_attributes(ont_hash, sub)
    ont_hash[:submissionStatus] = sub.submissionStatus
    ont_hash[:deprecated] = sub.deprecated
    ont_hash[:status] = sub.status
    ont_hash[:submission] = true
    ont_hash[:pullLocation] = sub.pullLocation
    ont_hash[:description] = sub.description
    ont_hash[:creationDate] = sub.creationDate
    ont_hash[:released] = sub.released
    ont_hash[:naturalLanguage] = sub.naturalLanguage
    ont_hash[:hasFormalityLevel] = sub.hasFormalityLevel
    ont_hash[:isOfType] = sub.isOfType
    ont_hash[:submissionStatusFormatted] = submission_status2string(sub).gsub(/\(|\)/, '')
    ont_hash[:format] = sub.hasOntologyLanguage
    ont_hash[:contact] = sub.contact.map(&:name).first unless sub.contact.nil?
  end

  def add_ontology_attributes(ont_hash, ont)
    return  if ont.nil?

    ont_hash[:id] = ont.id
    ont_hash[:type] = ont.viewOf.nil? ? 'ontology' : 'ontology_view'
    ont_hash[:show] = ont.viewOf.nil? ? true : false # show ontologies only by default
    ont_hash[:groups] = ont.group || []
    ont_hash[:categories] = ont.hasDomain || []
    ont_hash[:private] = ont.private?
    ont_hash[:submissionStatus] = []
    ont_hash[:administeredBy] = ont.administeredBy
    ont_hash[:name] = ont.name
    ont_hash[:acronym] = ont.acronym
    ont_hash[:projects] = ont.projects
    ont_hash[:notes] = ont.notes
    ont_hash[:viewOfOnt] = ont.viewOf
  end

  def add_fair_score_metrics(ont_hash, ont)
    if !@fair_scores.nil? && !@fair_scores[ont.acronym].nil?
      ont_hash[:fairScore] = @fair_scores[ont.acronym]['score']
      ont_hash[:normalizedFairScore] = @fair_scores[ont.acronym]['normalizedScore']
    else
      ont_hash[:fairScore] = nil
      ont_hash[:normalizedFairScore] = 0
    end
  end

  def ontology_filters_init(categories, groups)
    @languages = submission_metadata.select { |x| x['@id']['naturalLanguage'] }.first['enforcedValues'].map do |id, name|
      { 'id' => id, 'name' => name, 'value' => id.split('/').last, 'acronym' => name }
    end

    @formalityLevel = submission_metadata.select { |x| x['@id']['hasFormalityLevel'] }.first['enforcedValues'].map do |id, name|
      { 'id' => id, 'name' => name, 'acronym' => name.camelize(:lower), 'value' => name.delete(' ')}
    end

    @isOfType = submission_metadata.select { |x| x['@id']['isOfType'] }.first['enforcedValues'].map do |id, name|
      { 'id' => id, 'name' => name, 'acronym' => name.camelize(:lower), 'value' => name.delete(' ') }
    end

    @formats = [['All formats', ''], 'OBO', 'OWL', 'SKOS', 'UMLS']
    @sorts_options = [['Sort by', ''], ['Name', 'ontology_name'],
                      ['Class count', 'metrics_classes'], ['Instances/Concepts count', 'metrics_individuals'],
                      ['Upload date', 'creationDate'], ['Release date', 'released']]

    init_filters(params)
    # @missingStatus = [
    #   {'id' => 'RDF', 'name' => 'RDF', 'acronym' => 'RDF'},
    #   {'id' => 'ABSOLETE', 'name' => 'ABSOLETE', 'acronym' => 'ABSOLETE'},
    #   {'id' => 'METRICS', 'name' => 'METRICS', 'acronym' => 'METRICS'},
    #   {'id' => 'RDF_LABELS', 'name' => 'RDF LABELS', 'acronym' => 'RDFLABELS'},
    #   {'id' => 'UPLOADED', 'name' => 'UPLOADED', 'acronym' => 'UPLOADED'},
    #   {'id' => 'INDEXED_PROPERTIES', 'name' => 'INDEXED PROPERTIES', 'acronym' => 'INDEXED_PROPERTIES'},
    #   {'id' => 'ANNOTATOR', 'name' => 'ANNOTATOR', 'acronym' => 'ANNOTATOR'},
    #   {'id' => 'DIFF', 'name' => 'DIFF', 'acronym' => 'DIFF'}
    # ]

    {
      categories: object_filter(categories, :categories),
      groups: object_filter(groups, :groups),
      naturalLanguage: object_filter(@languages, :naturalLanguage),
      hasFormalityLevel: object_filter(@formalityLevel, :hasFormalityLevel),
      isOfType: object_filter(@isOfType, :isOfType),
      #missingStatus: object_filter(@missingStatus, :missingStatus)
    }
  end

  def check_id(name_value, objects, name_key)
    selected_category = objects.select { |x| x[name_key].parameterize.underscore.eql?(name_value.parameterize.underscore) }
    selected_category.first && selected_category.first['id']
  end

  def object_checks(key)
    params[key]&.split(',')
  end

  def object_filter(objects, object_name, name_key = 'acronym')
    checks = object_checks(object_name) || []
    checks = checks.map { |x| check_id(x, objects, name_key) }.compact

    ids = objects.map { |x| x['id'] }
    count = ids.count { |x| checks.include?(x) }
    [objects, checks, count]
  end

  def count_objects(ontologies)
    objects_count = {}
    @categories = LinkedData::Client::Models::Category.all(display_links: false, display_context: false)
    @groups = LinkedData::Client::Models::Group.all(display_links: false, display_context: false)
    @filters = ontology_filters_init(@categories, @groups)
    object_names = @filters.keys


    @filters.each do |filter, values|
      objects = values.first
      objects_count[filter] = objects.map { |v| [v['id'], 0] }.to_h
    end

    ontologies.each do |ontology|
      object_names.each do |name|
        values = Array(ontology[name])
        values.each do |v|
          objects_count[name] = {} unless objects_count[name]
          objects_count[name][v] = (objects_count[name][v] || 0) + 1
        end
      end
    end
    objects_count
  end

end

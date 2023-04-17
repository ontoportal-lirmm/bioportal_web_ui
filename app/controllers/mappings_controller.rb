require 'cgi'

class MappingsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include TurboHelper
  include MappingStatistics
  include MappingsHelper
  include TurboHelper
  layout :determine_layout
  before_action :authorize_and_redirect, only: [:create, :new, :destroy]

  EXTERNAL_URL_PARAM_STR = "mappings:external"
  INTERPORTAL_URL_PARAM_STR = "interportal:"

  INTERPORTAL_HASH = $INTERPORTAL_HASH ||= {}

  def index
    ontology_list = LinkedData::Client::Models::Ontology.all.select { |o| !o.summaryOnly }
    ontologies_mapping_count = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}/statistics/ontologies")
    ontologies_hash = {}
    ontology_list.each do |ontology|
      ontologies_hash[ontology.acronym] = ontology
    end

    # TODO_REV: Views support for mappings
    # views_list.each do |view|
    #   ontologies_hash[view.ontologyId] = view
    # end

    @options = {}
    ontologies_mapping_count&.members&.each do |ontology_acronym|
      # Adding external and interportal mappings to the dropdown list
      if ontology_acronym.to_s == EXTERNAL_MAPPINGS_GRAPH
        mapping_count = ontologies_mapping_count[ontology_acronym.to_s] || 0
        select_text = "External Mappings (#{number_with_delimiter(mapping_count, delimiter: ',')})" if mapping_count >= 0
        ontology_acronym = EXTERNAL_URL_PARAM_STR
      elsif ontology_acronym.to_s.start_with?(INTERPORTAL_MAPPINGS_GRAPH)
        mapping_count = ontologies_mapping_count[ontology_acronym.to_s] || 0
        select_text = "Interportal Mappings - #{ontology_acronym.to_s.split("/")[-1].upcase} (#{number_with_delimiter(mapping_count, delimiter: ',')})" if mapping_count >= 0
        ontology_acronym = INTERPORTAL_URL_PARAM_STR + ontology_acronym.to_s.split("/")[-1]
      else
        ontology = ontologies_hash[ontology_acronym.to_s]
        mapping_count = ontologies_mapping_count[ontology_acronym] || 0
        next unless ontology && mapping_count > 0
        select_text = "#{ontology.name} - #{ontology.acronym} (#{number_with_delimiter(mapping_count, delimiter: ',')})"
      end
      @options[select_text] = ontology_acronym
    end

    @options = @options.sort
  end

  def count
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    @ontology_acronym = @ontology&.acronym || params[:id]
    @mapping_counts = mapping_counts(@ontology_acronym)
    render partial: 'count'
  end

  def loader
    @example_code = [{
                       "classes": ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Image_Algorithm",
                                   "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000202"],

                       "name": 'This is the mappings produced to test the bulk load',
                       "source": 'https://w3id.org/semapv/LexicalMatching',
                       "comment": 'mock data',
                       "relation": [
                         'http://www.w3.org/2002/07/owl#subClassOf'
                       ],
                       "subject_source_id": 'http://bioontology.org/ontologies/BiomedicalResources.owl',
                       "object_source_id": 'http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl',
                       "source_name": 'https://w3id.org/sssom/mapping/tests/data/basic.tsv',
                       "source_contact_info": 'orcid:1234,orcid:5678',
                       "date": '2020-05-30'
                     }]
    render partial: 'mappings/bulk_loader/loader'
  end

  def loader_process
    response = LinkedData::Client::HTTP.post('/mappings/load', file: params[:file])
    errors = response.errors
    errors = errors.to_h.except(:links, :context) if errors

    created = response.created
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('file_loader_result',
                                                  partial: 'mappings/bulk_loader/loaded_mappings',
                                                  locals: { errors: errors, created: created })
      end
      format.html { redirect_to mappings_path }
    end
  end

  def show
    @mapping = request_mapping
    mapping_form(mapping: @mapping)
    respond_to do |format|
      format.html { render 'mappings/edit', layout: false }
    end

  end

  def show_mappings
    page = params[:page] || 1
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:id]).first
    @target_ontology = LinkedData::Client::Models::Ontology.find(params[:target])

    # Cases if ontology or target are interportal or external
    if @ontology.nil?
      ontology_acronym = params[:id]
      if params[:id] == EXTERNAL_URL_PARAM_STR
        @ontology_name = "External Mappings"
      elsif params[:id].start_with?(INTERPORTAL_URL_PARAM_STR)
        @ontology_name = params[:id].sub(":", " - ")
      end
    else
      ontology_acronym = @ontology.acronym
      @ontology_name = @ontology.name
    end
    if @target_ontology.nil?
      if params[:target] == EXTERNAL_MAPPINGS_GRAPH
        target_acronym = EXTERNAL_URL_PARAM_STR
        @target_ontology_name = "External Mappings"
      elsif params[:target].start_with?(INTERPORTAL_MAPPINGS_GRAPH)
        target_acronym = "#{INTERPORTAL_URL_PARAM_STR}:#{params[:target].split("/")[-1]}"
        @target_ontology_name = "Interportal - #{params[:target].split("/")[-1].upcase}"
      end
    else
      target_acronym = @target_ontology.acronym
      @target_ontology_name = @target_ontology.name
    end

    ontologies = [ontology_acronym, target_acronym]

    @mapping_pages = LinkedData::Client::HTTP.get("#{MAPPINGS_URL}", { page: page, ontologies: ontologies.join(',') })
    @mappings = @mapping_pages.collection
    @delete_mapping_permission = check_delete_mapping_permission(@mappings)

    if @mapping_pages.nil? || @mapping_pages.collection.empty?
      @mapping_pages = MappingPage.new
      @mapping_pages.page = 1
      @mapping_pages.pageCount = 1
      @mapping_pages.collection = []
    end

    total_results = @mapping_pages.pageCount * @mapping_pages.collection.length

    # This converts the mappings into an object that can be used with the pagination plugin
    @page_results = WillPaginate::Collection.create(@mapping_pages.page, @mapping_pages.collection.length, total_results) do |pager|
      pager.replace(@mapping_pages.collection)
    end

    render partial: 'show'
  end

  def get_concept_table
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontologyid]).first
    @concept = @ontology.explore.single_class({ full: true }, params[:conceptid])

    @mappings = @concept.explore.mappings

    @delete_mapping_permission = check_delete_mapping_permission(@mappings)
    render turbo_stream: [
      replace('mapping_count') { "#{@mappings.size}" },
      replace('concept_mappings', partial: 'mappings/concept_mappings')
    ]

  end

  def new
    mapping_form
    respond_to do |format|
      format.html { render action: 'new', layout: false }
    end
  end

  # POST /mappings
  # POST /mappings.xml
  def create
    values, @concept = mapping_form_values
    errors = valid_values?(values)
    if errors.empty?
      @mapping, = LinkedData::Client::Models::Mapping.new(values: values)
      @mapping_saved = @mapping.save
      errors << @mapping_saved.errors if @mapping_saved.errors
    end

    respond_to do |format|
      format.turbo_stream do
        if !errors.empty?
          render turbo_stream: alert_error { JSON.pretty_generate errors }
        else
          @delete_mapping_permission = check_delete_mapping_permission(@mapping_saved)
          mapping = LinkedData::Client::Models::Mapping.find(@mapping_saved.id)
          render turbo_stream: [
            alert(type: 'success') { 'Mapping created' },
            prepend('concept_mappings_table_content', partial: 'show_line', locals: { map: mapping, concept: @concept })
          ]
        end
      end
    end
  end

  def update
    values, @concept = mapping_form_values
    @mapping = request_mapping
    errors = valid_values?(values)
    if errors.empty?
      map_uri = "#{MAPPINGS_URL}/#{@mapping.id.split('/').last}"
      response = LinkedData::Client::HTTP.patch(map_uri, values)
      errors << response.body if response.status != 204
    end

    respond_to do |format|
      format.turbo_stream do
        if !errors.empty? || @mapping.nil?
          render_turbo_stream(alert_error { JSON.pretty_generate errors })
        else
          render_turbo_stream(
            alert_success { 'Mapping updated' },
            replace(@mapping.id.split('/').last, partial: 'show_line', locals: { map: request_mapping, concept: @concept })
          )
        end
      end
    end

  end

  def destroy
    error = nil
    success_text = ''
    map_id = params[:id].gsub(':/', '://')
    map_uri = "#{MAPPINGS_URL}/#{CGI.escape(map_id)}"
    result = LinkedData::Client::HTTP.delete(map_uri)
    if result.status == 204
      success_text = "#{map_id} deleted successfully"
    else
      error = result.body
    end
    respond_to do |format|
      format.turbo_stream do
        if error.nil?
          render turbo_stream: [
            alert(type: 'success') { success_text },
            turbo_stream.remove(map_id.split('/').last)
          ]

        else
          render alert(type: 'danger') { error }
        end
      end
      format.html { render json: { success: success_text, error: error } }
    end

  end

  private

  def mapping_form(mapping: nil)
    if mapping
      mapping.classes.each do |cls|
        if cls.id.eql?(params[:conceptid_from])
          @concept_from = cls
          @ontology_from = cls.explore.ontology
        else
          @concept_to = cls
          @mapping_type = if inter_portal_mapping?(@concept_to)
                            'interportal'
                          elsif internal_mapping?(@concept_to)
                            'internal'
                          else
                            'external'
                          end
          set_mapping_target(concept_to_id: @concept_to.id, ontology_to: @concept_to.links['ontology'],
                             mapping_type: @mapping_type)
        end
      end
    else
      mapping = LinkedData::Client::Models::Mapping.new
      @ontology_from = LinkedData::Client::Models::Ontology.find(params[:ontology_from])
      @ontology_to = LinkedData::Client::Models::Ontology.find(params[:ontology_to])
      @concept_from = @ontology_from.explore.single_class({ full: true }, params[:conceptid_from]) if @ontology_from
      if @ontology_to
        @concept_to = @ontology_to.explore.single_class({ full: true }, params[:conceptid_to])
        @map_to_bioportal_ontology_id = @ontology_to.id
      end
    end

    @interportal_options = []
    INTERPORTAL_HASH.each do |key, value|
      @interportal_options.push([key, value['api']])
    end

    @mapping_relation_options = [
      ["Identical (skos:exactMatch)", "http://www.w3.org/2004/02/skos/core#exactMatch"],
      ["Similar (skos:closeMatch)", "http://www.w3.org/2004/02/skos/core#closeMatch"],
      ["Related (skos:relatedMatch)", "http://www.w3.org/2004/02/skos/core#relatedMatch"],
      ["Broader (skos:broadMatch)", "http://www.w3.org/2004/02/skos/core#broadMatch"],
      ["Narrower (skos:narrowMatch)", "http://www.w3.org/2004/02/skos/core#narrowMatch"],
      ["Translation (gold:translation)", "http://purl.org/linguistics/gold/translation"],
      ["Free Translation (gold:freeTranslation)", "http://purl.org/linguistics/gold/freeTranslation"]
    ]
    @mapping_name = mapping.process&.name
    @mapping_comment = mapping.process&.comment
    @mapping_source_name = mapping.process&.source_name
    @mapping_source_contact_info = mapping.process&.source_contact_info
    @mapping_source = mapping.process&.source
    @selected_relation = mapping.process.nil? ? @mapping_relation_options.first : mapping.process.relation.first
  end

  def mapping_form_values
    target_ontology, target, external_mapping = get_mappings_target
    source_ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:map_from_bioportal_ontology_id]).first
    source = source_ontology.explore.single_class(params[:map_from_bioportal_full_id])
    values = {
      classes: [
        source.id,
        target
      ],
      subject_source_id: source_ontology.id,
      object_source_id: target_ontology,
      creator: session[:user].id,
      external_mapping: external_mapping,
      relation: Array(params[:mapping][:relation]),
      source_contact_info: params[:mapping][:source_contact_info],
      source_name: params[:mapping][:source_name],
      name: params[:mapping][:name],
      comment: params[:mapping][:comment]
    }

    [values, source]
  end

  def request_mapping
    mapping = LinkedData::Client::Models::Mapping.find(params[:id])
    not_found("Mapping #{params[:id]} not found") if mapping.nil? || mapping.errors
    mapping
  end

  def valid_values?(values)
    errors = []
    if values[:classes].reject(&:blank?).size != 2
      errors << 'Source and target concepts need to be specified'
    end
    errors
  end
end

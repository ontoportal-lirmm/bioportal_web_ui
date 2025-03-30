require 'json'
require 'cgi'

class AnnotatorController < ApplicationController
  layout :determine_layout
  include AnnotatorHelper
  include ApplicationHelper

  ANNOTATOR_URI = $ANNOTATOR_URL

  before_action :initialize_options, only: [:index]

  def index
    @results_table_header = annotator_results_table_header
    @advanced_options_open = !empty_advanced_options
    set_annotator_info('/annotator', 'Annotator', ANNOTATOR_URI)
  end

  private

  def set_annotator_info(url, page_name, uri)
    @form_url = url
    @page_name = page_name
    annotator_results(uri)
  end

  def annotator_results(uri)
    @annotator_ontologies = LinkedData::Client::Models::Ontology.all
    # TODO remove this
    @ontologies = LinkedData::Client::Models::Ontology.all({ include_views: true }).map { |o| [o.id.to_s, o] }.to_h

    return unless params[:text] && !params[:text].empty?

    @init_whole_word_only = true
    api_params = get_api_params
    @json_link = json_link(uri, api_params)
    @rdf_link = "#{@json_link}&format=rdf"

    @direct_results = 0
    @parents_results = 0

    # if we are in a slice, pass the ontologies of this slice in the params
    if at_slice?
      slice_ontologies_acronyms = @subdomain_filter[:ontologies].map { |id| link_last_part(id) }
      if api_params[:ontologies]
        selected_ontologies = api_params[:ontologies].split(',')
        filtered_ontologies = selected_ontologies.select { |ontology| slice_ontologies_acronyms.include?(ontology) }
      else
        filtered_ontologies = slice_ontologies_acronyms
      end
      api_params[:ontologies] = filtered_ontologies.join(',')
    end

    params[:score] = nil if params[:score].nil? || params[:score].eql?('none')
    annotations = find_annotations(uri, api_params)
    @semantic_types = get_semantic_types
    @results = []
    annotations.each do |annotation|
      @direct_results += 1
      if annotation.annotations.empty?
        @results.push(direct_annotation(annotation))
      else
        row = direct_annotation(annotation)
        add_context_annotations(annotation, row)
        index = @results.find_index { |result| result[:class] == row[:class] }
        if index
          @results[index][:context].unshift(*row[:context])
          @results[index][:score] = @results[index][:score].to_i + row[:score].to_i
        else
          @results.push(row)
        end
      end

      annotation.hierarchy.each do |parent|
        row = parent_annotation(parent, annotation)
        index = @results.find_index { |result| result[:class] == row[:class] }
        if index
          @results[index][:context] += row[:context]
          @results[index][:score] = @results[index][:score].to_i + row[:score].to_i
        else
          add_fast_context(row, annotation.annotations[0])
          @results.push(row)
        end
        @parents_results += 1
      end
    end
  end

  def get_semantic_types
    semantic_types = {}
    sty_ont = LinkedData::Client::Models::Ontology.find_by_acronym('STY').first
    return semantic_types if sty_ont.nil?

    # The first 500 items should be more than sufficient to get all semantic types.
    sty_classes = sty_ont.explore.classes({ 'pagesize' => 500, include: 'prefLabel' })
    Array(sty_classes.collection).each do |cls|
      code = cls.id.split('/').last
      semantic_types[code] = cls.prefLabel
    end
    semantic_types
  end

  def annotation_class_info(cls)
    {
      text: cls.prefLabel,
      link: url_to_endpoint(cls.links['self'])
    }
  end

  def annotation_ontology_info(ontology_url)
    {
      text: @ontologies[ontology_url].name,
      link: url_to_endpoint(ontology_url)
    }
  end

  def initialize_options
    @semantic_types_for_select = []
    @semantic_groups_for_select = []
    @semantic_types ||= get_semantic_types
    @sem_type_ont = LinkedData::Client::Models::Ontology.find_by_acronym('STY').first
    @semantic_groups ||= { 'ACTI' => 'Activities & Behaviors', 'ANAT' => 'Anatomy', 'CHEM' => 'Chemicals & Drugs', 'CONC' => 'Concepts & Ideas', 'DEVI' => 'Devices', 'DISO' => 'Disorders', 'GENE' => 'Genes & Molecular Sequences', 'GEOG' => 'Geographic Areas', 'LIVB' => 'Living Beings', 'OBJC' => 'Objects', 'OCCU' => 'Occupations', 'ORGA' => 'Organizations', 'PHEN' => 'Phenomena', 'PHYS' => 'Physiology', 'PROC' => 'Procedures' }
    @semantic_types.each_pair do |code, label|
      @semantic_types_for_select << ["#{label} (#{code})", code]
    end
    @semantic_groups.each_pair do |group, label|
      @semantic_groups_for_select << ["#{label} (#{group})", group]
    end
    @semantic_types_for_select.sort! { |a, b| a[0] <=> b[0] }
    @semantic_groups_for_select.sort! { |a, b| a[0] <=> b[0] }
    @ancestors_levels = %w[None 1 2 3 4 5 6 7 8 9 10 All]
    @include_score = %w[none old cvalue cvalueh]
  end

  def empty_advanced_options
    params[:semantic_types].nil? &&
      params[:semantic_groups].nil? &&
      params[:class_hierarchy_max_level] == 'None' &&
      (params[:score].nil? || params[:score] == 'none') &&
      params[:score_threshold] == '0' &&
      params[:confidence_threshold] == '0' &&
      params[:fast_context].nil? &&
      params[:lemmatize].nil?
  end

  def remove_special_chars(input)
    regex = /^[a-zA-Z0-9\s]*$/
    input.gsub!(/[^\w\s]/, '') unless input.match?(regex)
    input
  end

end

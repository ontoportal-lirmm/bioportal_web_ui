require 'json'
require 'cgi'

class AnnotatorController < ApplicationController
  layout :determine_layout
  include ApplicationHelper

  ANNOTATOR_URI = $ANNOTATOR_URL
  ANNOTATOR_PLUS_URI = $ANNOTATOR_URL+"/annotatorplus"
  NCBO_ANNOTATOR_PLUS_URI = $NCBO_ANNOTATOR_URL

  before_action :initialize_options, only: [:index, :annotator_plus, :ncbo_annotator_plus]
  def index
    set_annotator_info('/annotator', 'Annotator', ANNOTATOR_URI)
  end

  def annotator_plus
    set_annotator_info('/annotatorplus', 'Annotator +', ANNOTATOR_PLUS_URI)
    render 'index'
  end

  def ncbo_annotator_plus
    params[:apikey] = $NCBO_API_KEY
    set_annotator_info('/ncbo_annotatorplus', 'NCBO Annotator +', NCBO_ANNOTATOR_PLUS_URI)
    render 'index'
  end

  private
  def set_annotator_info(url, page_name, uri)
    @form_url = url
    @page_name = page_name
    annotator_results(uri)
  end
  def annotator_results(uri)
    @advanced_options_open = false
    @annotator_ontologies = LinkedData::Client::Models::Ontology.all
    if params[:text] && !params[:text].empty?
      @init_whole_word_only = true
      api_params = {
        text: remove_special_chars(params[:text]),
        ontologies: params[:ontologies],
        semantic_types: params[:semantic_types],
        semantic_groups: params[:semantic_groups],
        whole_word_only: params[:whole_word_only],
        longest_only: params[:longest_only],
        expand_mappings: params[:expand_mappings],
        exclude_numbers: params[:exclude_numbers],
        exclude_synonyms: params[:exclude_synonyms],
        semantic_types: params[:semantic_types],
        semantic_groups: params[:semantic_groups],
        class_hierarchy_max_level: params[:class_hierarchy_max_level],
        score_threshold: params[:score_threshold],
        confidence_threshold: params[:confidence_threshold],
        fast_context: params[:fast_context],
        lemmatize: params[:lemmatize]
      }
      unless params[:score].eql?('none')
        api_params[:score] = params[:score]
      end
      @json_link = json_link(uri, api_params)
      @rdf_link = "#{@json_link}&format=rdf"
      @results_table_header = [
        t('annotator.class'), t('annotator.ontology'), t('annotator.context')
      ]
      if params[:fast_context]
        @results_table_header += [t('annotator.negation'), t('annotator.experiencer'), t('annotator.temporality'), t('annotator.certainty')]
      end
      @direct_results = 0
      @parents_results = 0
      if params[:score].nil? || params[:score].eql?('none')
        params[:score] = nil
      else
        @results_table_header.push(t('annotator.score'))
      end
      annotations = LinkedData::Client::HTTP.get(uri, api_params)
      @ontologies = get_simplified_ontologies_hash
      @semantic_types = get_semantic_types 
      @results = []
      annotations.each do |annotation|
        if annotation.annotations.empty?
          row = {
            class: annotation_class_info(annotation.annotatedClass),
            ontology: annotation_ontology_info(annotation.annotatedClass.links),
            context: "",
            type: 'direct'
          }
          unless params[:score].eql?('none')
            row[:score] = annotation.score.nil? ? '' : sprintf("%.2f", annotation.score)
          end
          @direct_results = @direct_results + 1
          @results.push(row)
        else
          row = {
              class: annotation_class_info(annotation.annotatedClass),
              ontology: annotation_ontology_info(annotation.annotatedClass.links["ontology"]),
              context: [],
              type: 'direct'
          }
          unless params[:score].eql?('none')
            row[:score] = annotation.score.nil? ? '' : sprintf("%.2f", annotation.score)
          end
          annotation.annotations.each do |a|
            row[:context].push(a)
            if params[:fast_context]
              row[:negation] = a.negationContext
              row[:experiencer] = a.experiencerContext
              row[:temporality] = a.temporalityContext
              row[:certainty] = a.certaintyContext
            end
          end
          index = @results.find_index { |result| result[:class] == row[:class] }
          if index
            @results[index][:context].unshift(*row[:context])
            @results[index][:score] = @results[index][:score].to_i + row[:score].to_i
          else
            @results.push(row)
          end
          @direct_results = @direct_results + 1
        end
        annotation.hierarchy.each do |parent|
            row = {
              class: annotation_class_info(parent.annotatedClass),
              ontology: annotation_ontology_info(parent.annotatedClass.links["ontology"]),
              context: [{child: annotation_class_info(annotation.annotatedClass), level: parent.distance}],
              type: 'parent'
            }
            unless params[:score].eql?('none')
              row[:score] = parent.score.nil? ? '' : sprintf("%.2f", parent.score)
            end
            index = @results.find_index { |result| result[:class] == row[:class] }
            if index
              @results[index][:context] += row[:context]
              @results[index][:score] = @results[index][:score].to_i + row[:score].to_i
            else
              if params[:fast_context]
                row[:negation] = annotation.annotations[0].negationContext
                row[:experiencer] = annotation.annotations[0].experiencerContext
                row[:temporality] = annotation.annotations[0].temporalityContext
                row[:certainty] = annotation.annotations[0].certaintyContext
              end
              @results.push(row)
            end
            @parents_results = @parents_results + 1
        end
      end
      @advanced_options_open = !empty_advanced_options
    end
  end

  def get_semantic_types
    semantic_types = {}
    sty_ont = LinkedData::Client::Models::Ontology.find_by_acronym('STY').first
    return semantic_types if sty_ont.nil?
    # The first 500 items should be more than sufficient to get all semantic types.
    sty_classes = sty_ont.explore.classes({'pagesize'=>500, include: 'prefLabel'})
    Array(sty_classes.collection).each do |cls|
      code = cls.id.split("/").last
      semantic_types[ code ] = cls.prefLabel
    end
    semantic_types
  end

  def annotation_class_info(cls)
    return {
      text: cls.prefLabel,
      link: url_to_endpoint(cls.links["self"])
    }
  end
  def annotation_ontology_info(ontology_url)
    return {
      text: @ontologies[ontology_url][:name],
      link: url_to_endpoint(ontology_url)
    }
  end

  def initialize_options
    @semantic_types_for_select = []
    @semantic_groups_for_select = []
    @semantic_types ||= get_semantic_types
    @sem_type_ont = LinkedData::Client::Models::Ontology.find_by_acronym('STY').first
    @semantic_groups ||= {"ACTI" => "Activities & Behaviors", "ANAT" => "Anatomy", "CHEM" => "Chemicals & Drugs","CONC" => "Concepts & Ideas","DEVI" => "Devices", "DISO" => "Disorders", "GENE" => "Genes & Molecular Sequences", "GEOG" => "Geographic Areas", "LIVB" => "Living Beings","OBJC" => "Objects", "OCCU" => "Occupations", "ORGA" => "Organizations", "PHEN" => "Phenomena", "PHYS" => "Physiology","PROC" => "Procedures"}
    @semantic_types.each_pair do |code, label|
      @semantic_types_for_select << ["#{label} (#{code})", code]
    end
    @semantic_groups.each_pair do |group, label|
        @semantic_groups_for_select << ["#{label} (#{group})", group]
    end 
    @semantic_types_for_select.sort! {|a,b| a[0] <=> b[0]}
    @semantic_groups_for_select.sort! {|a,b| a[0] <=> b[0]}
    @ancestors_levels = ['None', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'All']
    @include_score = ['none', 'old', 'cvalue', 'cvalueh']
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
    unless input.match?(regex)
      input.gsub!(/[^\w\s]/, '')
    end
    input
  end

end


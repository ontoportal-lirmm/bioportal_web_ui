require 'json'
require 'cgi'

class AnnotatorController < ApplicationController
  layout :determine_layout

  # REST_URI is defined in application_controller.rb
  #ANNOTATOR_URI = REST_URI + "/annotator"
  ANNOTATOR_URI = $ANNOTATOR_URL
  ANNOTATOR_PLUS_URI = $ANNOTATOR_URL+"/annotatorplus"
  NCBO_ANNOTATOR_PLUS_URI = $NCBO_ANNOTATOR_URL

  def index
    initalize_options
    @form_url = '/annotator'
    @page_name = 'Annotator'
    @json_link = json_link(ANNOTATOR_URI)
    @rdf_link = "#{@json_link}&format=rdf"
    annotator_results(ANNOTATOR_URI)
  end
  
  def annotator_plus
    initalize_options
    @form_url = '/annotatorplus'
    @page_name = 'Annotator +'
    @json_link = json_link(ANNOTATOR_PLUS_URI)
    @rdf_link = "#{@json_link}&format=rdf"
    annotator_results(ANNOTATOR_PLUS_URI)
    render 'index'
  end

  def ncbo_annotator_plus
    initalize_options
    @form_url = '/ncbo_annotatorplus'
    @page_name = 'NCBO Annotator +'
    @json_link = json_link(NCBO_ANNOTATOR_PLUS_URI)
    @rdf_link = "#{@json_link}&format=rdf"
    annotator_results(NCBO_ANNOTATOR_PLUS_URI)
    render 'index'
  end

  private
  def annotator_results(uri)
    @advanced_options_open = false
    @annotator_ontologies = LinkedData::Client::Models::Ontology.all
    if params[:text] && !params[:text].empty?
      params[:ontologies] = params[:ontologies_list]&.join(',') || ''
      params[:semantic_types] = params[:semantic_types_list]&.join(',') || ''
      text_to_annotate = params[:text].strip.gsub("\r\n", " ").gsub("\n", " ")
      @results_table_header = [
        "Class", "Ontology", "Contexts"
      ]

      if params[:fast_context]
        params[:certainty] == true
        params[:temporality] == true
        params[:experiencer] == true
        params[:negation] == true
        @results_table_header += ['Negation', 'Experiencer', 'Temporality', 'Certainty']
      end
      @direct_results = 0
      @parents_results = 0
      if params[:score].nil? || params[:score].eql?('none')
        params[:score] = nil
      else
        @results_table_header.push('Score')
      end
      
      annotations = LinkedData::Client::HTTP.get(uri, params)
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
    sty_classes.collection.each do |cls|
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
  def url_to_endpoint(url)
    uri = URI.parse(url)
    endpoint = uri.path.sub(/^\//, '')
    endpoint
  end

  def initalize_options
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
    !params[:semantic_types_list] && !params[:semantic_groups_list] && params[:class_hierarchy_max_level].eql?('None') && (!params[:score] || params[:score].eql?('none')) && params[:score_threshold].eql?('0') && params[:confidence_threshold].eql?('0') && !params[:fast_context] && !params[:lemmatize]
  end

  def json_link(url)
    base_url = "#{url}?text=#{params[:text]}&"
    optional_params = {
      "ontologies" => params[:ontologies],
      "whole_word_only" => params[:whole_word_only],
      "longest_only" => params[:longest_only],
      "expand_mappings" => params[:expand_mappings],
      "exclude_numbers" => params[:exclude_numbers],
      "exclude_synonyms" => params[:exclude_synonyms],
      "semantic_types" => params[:semantic_types],
      "semantic_groups" => params[:semantic_groups],
      "class_hierarchy_max_level" => params[:class_hierarchy_max_level],
      "score" => params[:score],
      "score_threshold" => params[:score_threshold],
      "confidence_threshold" => params[:confidence_threshold],
      "fast_context" => params[:fast_context],
      "lemmatize" => params[:lemmatize]
    }
    
    filtered_params = optional_params.reject { |_, value| value.nil? }
    optional_params_str = filtered_params.map { |param, value| "#{param}=#{value}" }.join("&")
    return base_url + optional_params_str + '&apikey=1de0a270-29c5-4dda-b043-7c3580628cd5'
  end

end


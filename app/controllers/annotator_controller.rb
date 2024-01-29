require 'json'
require 'cgi'

class AnnotatorController < ApplicationController
  layout :determine_layout

  # REST_URI is defined in application_controller.rb
  #ANNOTATOR_URI = REST_URI + "/annotator"
  ANNOTATOR_URI = $ANNOTATOR_URL

  def index
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
    if !$MULTIPLE_RECOGNIZERS.nil? && $MULTIPLE_RECOGNIZERS == true
      # Get recognizers from ontologies_api only if asked
      @recognizers = parse_json(REST_URI + "/annotator/recognizers")
    else
      @recognizers = []
    end
    @annotator_ontologies = LinkedData::Client::Models::Ontology.all
    @text = params[:text]
    @ancestors_levels = ['None', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'All']
    @include_score = ['none', 'old', 'cvalue', 'cvalueh']
    if params[:text]
      text_to_annotate = params[:text].strip.gsub("\r\n", " ").gsub("\n", " ")
      @results_table_header = [
        "Class", "Ontology", "Contexts"
      ]

      if params[:score].nil? || params[:score].eql?('none')
        params[:score] = nil
      else
        @results_table_header.push('Score')
      end
      
      annotations = LinkedData::Client::HTTP.get(ANNOTATOR_URI, params)
      @ontologies = get_simplified_ontologies_hash
      @semantic_types = get_semantic_types 
      @results = []
      match_type_translation = {
          mgrep: "Direct",
          mapping: "Mapping",
          closure: "Ancestor"
      }
      annotations.each do |annotation|
        if annotation.annotations.length.eql?(0)
          row = {
            class: annotation_class_info(annotation.annotatedClass),
            ontology: annotation_ontology_info(annotation.annotatedClass.links),
            context: "",
            type: 'direct'
          }
          unless params[:score].eql?('none')
            row[:score] = annotation.score.nil? ? '' : sprintf("%.2f", annotation.score)
          end
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
          end
          @results.push(row)
        end
        annotation.hierarchy.each do |parent|
            row = {
              class: annotation_class_info(parent.annotatedClass),
              ontology: annotation_ontology_info(parent.annotatedClass.links["ontology"]),
              context: {child: annotation_class_info(annotation.annotatedClass), level: parent.distance},
              type: 'parent'
            }
            unless params[:score].eql?('none')
              row[:score] = parent.score.nil? ? '' : sprintf("%.2f", parent.score)
            end
            @results.push(row)
        end
      end
    end
    
    
  end

  private

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


  def massage_annotated_classes(annotations, options)
    # Get the class details required for display, assume this is necessary
    # for every element of the annotations array because the API returns a set.
    # Use the batch REST API to get all the annotated class prefLabels.
    start = Time.now
    semantic_types = options[:semantic_types] || []
    class_details = get_annotated_classes(annotations, semantic_types)
    simplify_annotated_classes(annotations, class_details)
    # repeat the simplification for any annotation hierarchy or mappings.
    hierarchy = annotations.map {|a| a if a.keys.include? 'hierarchy' }.compact
    hierarchy.each do |a|
      simplify_annotated_classes(a['hierarchy'], class_details) if not a['hierarchy'].empty?
    end
    mappings = annotations.map {|a| a if a.keys.include? 'mappings' }.compact
    mappings.each do |a|
      simplify_annotated_classes(a['mappings'], class_details) if not a['mappings'].empty?
    end
    LOG.add :debug, "Completed massage for annotated classes: #{Time.now - start}s"
  end

  def simplify_annotated_classes(annotations, class_details)
    annotations2delete = []
    annotations.each do |a|
      cls_id = a['annotatedClass']['@id']
      details = class_details[cls_id]
      if details.nil?
        LOG.add :debug, "Failed to get class details for: #{a['annotatedClass']['links']['self']}"
        annotations2delete.push(cls_id)
      else
        # Replace the annotated class with simplified details.
        a['annotatedClass'] = details
      end
    end
    # Remove any annotations that fail to resolve details.
    annotations.delete_if { |a| annotations2delete.include? a['annotatedClass']['@id'] }
  end

  def get_annotated_class_hash(a)
    return {
        :class => a['annotatedClass']['@id'],
        :ontology => a['annotatedClass']['links']['ontology']
    }
  end

  def get_annotated_classes(annotations, semantic_types=[])
    # Use batch service to get class prefLabels
    class_list = []
    annotations.each {|a| class_list << get_annotated_class_hash(a) }
    hierarchy = annotations.map {|a| a if a.keys.include? 'hierarchy' }.compact
    hierarchy.each do |a|
      a['hierarchy'].each {|h| class_list << get_annotated_class_hash(h) }
    end
    mappings = annotations.map {|a| a if a.keys.include? 'mappings' }.compact
    mappings.each do |a|
      a['mappings'].each {|m| class_list << get_annotated_class_hash(m) }
    end
    classes_simple = {}
    return classes_simple if class_list.empty?
    # remove duplicates
    class_set = class_list.to_set # get unique class:ontology set
    class_list = class_set.to_a   # collection requires a list in batch call
    # make the batch call
    properties = 'prefLabel'
    properties = 'prefLabel,semanticType' if not semantic_types.empty?
    call_params = {'http://www.w3.org/2002/07/owl#Class'=>{'collection'=>class_list, 'include'=>properties}}
    classes_json = get_batch_results(call_params)
    # Simplify the response data for the UI
    @ontologies_hash ||= get_simplified_ontologies_hash # application_controller
    classes_data = JSON.parse(classes_json)
    classes_data["http://www.w3.org/2002/07/owl#Class"].each do |cls|
      c = simplify_class_model(cls)
      ont_details = @ontologies_hash[ c[:ontology] ]
      next if ont_details.nil? # NO DISPLAY FOR ANNOTATIONS ON ANY CLASS OUTSIDE THE BIOPORTAL ONTOLOGY SET.
      c[:ontology] = ont_details
      unless semantic_types.empty? || cls['semanticType'].nil?
        @semantic_types ||= get_semantic_types   # application_controller
        # Extract the semantic type descriptions that are requested.
        semanticTypeURI = 'http://bioportal.bioontology.org/ontologies/umls/sty/'
        semanticCodes = cls['semanticType'].map {|t| t.sub( semanticTypeURI, '') }
        requestedCodes = semanticCodes.map {|code| (semantic_types.include? code and code) || nil }.compact
        requestedDescriptions = requestedCodes.map {|code| @semantic_types[code] }.compact
        c[:semantic_types] = requestedDescriptions
      else
        c[:semantic_types] = []
      end
      classes_simple[c[:id]] = c
    end
    return classes_simple
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

end


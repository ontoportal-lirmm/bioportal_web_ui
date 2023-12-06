# frozen_string_literal: true

class ConceptDetailsComponent < ViewComponent::Base
  include ApplicationHelper
  include MultiLanguagesHelper

  renders_one :header, TableComponent
  renders_many :sections, TableRowComponent

  attr_reader :concept_properties

  def initialize(id:, acronym:, properties:, top_keys:, bottom_keys:, exclude_keys:)
    @acronym = acronym
    @properties = properties
    @top_keys = top_keys
    @bottom_keys = bottom_keys
    @exclude_keys = exclude_keys
    @id = id

    @concept_properties = concept_properties2hash(@properties) if @properties
  end

  def add_sections(keys, &block)
    scheme_set = properties_set_by_keys(keys, prefix_properties(concept_properties))
    rows = row_hash_properties(scheme_set, concept_properties, &block)

    rows.each do |row|
      section do |table_row|
        table_row.create(*row)
      end
    end

  end

  def row_hash_properties(properties_set, ontology_acronym, &block)
    out = []
    properties_set&.each do |key, data|
      next if exclude_relation?(key) || !data[:values]

      values = data[:values]
      url = data[:key]

      ajax_links = values.map do |v|
        if block_given?
          block.call(v)
        else
          if v.is_a?(String)
            get_link_for_cls_ajax(v, ontology_acronym, '_blank')
          else
            display_in_multiple_languages([v].to_h)
          end
        end
      end if values.is_a?(Array)

      out << [
        { th: "<span title=#{url} data-controller='tooltip'>#{remove_owl_notation(key)}</span>".html_safe },
        { td: "<div class='d-flex flex-wrap'> #{"<p class='mx-1'>#{ajax_links&.join('</p><p class="mx-1">')}"}</div>".html_safe }
      ]
    end
    out
  end

  def properties_set_by_keys(keys, concept_properties, exclude_keys = [])
    concept_properties&.select do |k, v|
      (keys.include?(k) || !keys.select { |key| v[:key].to_s.include?(key) }.empty?) && !exclude_keys.include?(k) &&
        exclude_keys.select { |key| v[:key].to_s.include?(key) }.empty?
    end
  end

  def filter_properties(top_keys, bottom_keys, exclude_keys, concept_properties)
    all_keys = concept_properties&.keys || []
    top_set = properties_set_by_keys(top_keys, concept_properties, exclude_keys)
    bottom_set = properties_set_by_keys(bottom_keys, concept_properties, exclude_keys)
    leftover = properties_set_by_keys(all_keys - top_keys - bottom_keys, concept_properties, exclude_keys)
    [top_set, leftover, bottom_set]
  end

  private

  def concept_properties2hash(properties)
    # NOTE: example properties
    #
    # properties
    #=> #<struct
    #  http://www.w3.org/2000/01/rdf-schema#label=
    #    [#<struct
    #      object="Etiological thing",
    #      string="Etiological thing",
    #      links=nil,
    #      context=nil>],
    #  http://stagedata.bioontology.org/metadata/def/prefLabel=
    #    [#<struct
    #      object="Etiological thing",
    #      string="Etiological thing",
    #      datatype="http://www.w3.org/2001/XMLSchema#string",
    #      links=nil,
    #      context=nil>],
    #  http://www.w3.org/2000/01/rdf-schema#comment=
    #    [#<struct  object="AD444", string="AD444", links=nil, context=nil>],
    #  http://scai.fraunhofer.de/NDDUO#Synonym=
    #    [#<struct  object="Etiology", string="Etiology", links=nil, context=nil>],
    #  http://www.w3.org/2000/01/rdf-schema#subClassOf=
    #    ["http://www.w3.org/2002/07/owl#Thing"],
    #  http://www.w3.org/1999/02/22-rdf-syntax-ns#type=
    #    ["http://www.w3.org/2002/07/owl#Class"],
    #  links=nil,
    #  context=nil>
    properties_data = {}
    keys = properties.members # keys is an array of symbols
    keys.each do |key|
      next if properties[key].nil? # ignore :context and :links when nil.

      # Shorten the key into a simple label
      k = key.to_s if key.kind_of?(Symbol)
      k ||= key
      label = key
      if k.start_with?("http")
        label = LinkedData::Client::HTTP.get("/ontologies/#{@ontology.acronym}/properties/#{CGI.escape(k)}/label").label rescue ""
        if label.nil? || label.empty?
          k = k.gsub(/.*#/, '') # greedy regex replace everything up to last '#'
          k = k.gsub(/.*\//, '') # greedy regex replace everything up to last '/'
          # That might take care of nearly everything to be shortened.
          label = k
        end
      end
      begin
        # Try to simplify the property values, when they are a struct.
        if properties[key].is_a?(OpenStruct)
          values = language_hash(properties[key])
        else
          values = properties[key].map { |v| v.string }
        end
      rescue
        # Each value is probably a simple datatype already.
        values = properties[key]
      end
      data = { :key => key, :values => values }
      properties_data[label] = data
    end
    return properties_data
  end

  def exclude_relation?(relation_to_check, ontology = nil)
    excluded_relations = ["type", "rdf:type", "[R]", "SuperClass", "InstanceCount"]

    # Show or hide property based on the property and ontology settings
    if ontology
      # TODO_REV: Handle obsolete classes
      # Hide owl:deprecated if a user has set class or property based obsolete checking
      # if !ontology.obsoleteParent.nil? && relation_to_check.include?("owl:deprecated") || !ontology.obsoleteProperty.nil? && relation_to_check.include?("owl:deprecated")
      #   return true
      # end
    end

    excluded_relations.each do |relation|
      return true if relation_to_check.is_a?(Array) && relation_to_check.include?(relation)
    end
    return false
  end

end

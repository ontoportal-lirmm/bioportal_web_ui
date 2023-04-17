# frozen_string_literal: true

module MappingStatistics
  extend ActiveSupport::Concern


  MAPPINGS_URL = "#{LinkedData::Client.settings.rest_url}/mappings"

  MAPPING_STATISTICS_URL = "#{LinkedData::Client.settings.rest_url}/mappings/statistics/ontologies/"
  MAPPING_STATISTICS_EXTERNAL = "#{LinkedData::Client.settings.rest_url}/mappings/statistics/external"
  MAPPING_STATISTICS_INTERNAL = "#{LinkedData::Client.settings.rest_url}/mappings/statistics/interportal/"

  EXTERNAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/ExternalMappings"
  INTERPORTAL_MAPPINGS_GRAPH = "http://data.bioontology.org/metadata/InterportalMappings"

  def mapping_counts(source_acronym)
    mapping_counts = []

    ontologies = LinkedData::Client::Models::Ontology.all(
      include: 'acronym,name,summaryOnly',
      display_links: false,
      display_context: false
    )

    statistics = get_statistics source_acronym
    statistics&.each_pair do |target_acronym, count|
      if target_acronym.to_s == EXTERNAL_MAPPINGS_GRAPH
        ont = OpenStruct.new({:id => target_acronym.to_s, :name => "External Mappings"})
      elsif target_acronym.to_s.start_with?(INTERPORTAL_MAPPINGS_GRAPH)
        ont =OpenStruct.new( {:id => target_acronym.to_s, :name => "#{target_acronym.to_s.split("/")[-1].upcase} Interportal"})
      else
        ont = ontologies.find { |o| o.acronym.eql? target_acronym.to_s }
        # Handle the case where statistics are still present for a deleted ontology
        next  if ont.nil? || ont.summaryOnly
      end



      mapping_counts << { target_ontology: ont, count: count }
    end

    mapping_counts.sort! { |a, b| a[:target_ontology].name.downcase <=> b[:target_ontology].name.downcase }
  end

  private
  def get_statistics(source_acronym)
    ontology_label = source_acronym.split(":")
    if ontology_label[-1] == "external"
      counts = LinkedData::Client::HTTP.get(MAPPING_STATISTICS_EXTERNAL)
    elsif ontology_label[0] == "interportal"
      counts = LinkedData::Client::HTTP.get("#{MAPPING_STATISTICS_INTERNAL}#{ontology_label[-1]}")
    else
      counts = LinkedData::Client::HTTP.get("#{MAPPING_STATISTICS_URL}#{source_acronym}")
    end
    counts
  end



end

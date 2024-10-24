module MetricsHelper

  def portal_metrics(analytics)
    ontologies_acronym = if analytics.empty?
                           LinkedData::Client::Models::Ontology.all.map { |x| x.acronym }
                         else
                           analytics.keys
                         end

    metrics = ontologies_metrics(ontologies_acronym)

    ont_count = ontologies_acronym.size
    cls_count = metrics[:classes]
    individuals_count = metrics[:individuals]
    prop_count = metrics[:properties]
    map_count = total_mapping_count(ontologies_acronym)
    projects_count = LinkedData::Client::Models::Project.all.length
    users_count = LinkedData::Client::Models::User.all.length

    {
      ontologies_count: ont_count,
      class_count: cls_count,
      individuals_count: individuals_count,
      properties_count: prop_count,
      mappings_count: map_count,
      projects_count: projects_count,
      users_count: users_count
    }
  end

  def ontologies_metrics(ontologies_acronym = [])
    metrics = LinkedData::Client::Models::Metrics.all

    metrics.each_with_object(Hash.new(0)) do |h, sum|
      acronym = h.submission&.first&.split('/')&.dig(-3)
      next nil if acronym.nil?
      next nil unless ontologies_acronym.blank? || ontologies_acronym.include?(acronym)

      h.to_hash.slice(:classes, :properties, :individuals).each { |k, v| sum[k] += v }
    end
  end

  private

  def total_mapping_count
  def total_mapping_count(ontologies_acronym = [])
    total_count = 0
    begin
      stats = LinkedData::Client::HTTP.get(MappingStatistics::MAPPING_STATISTICS_URL)
      unless stats.blank?
        stats = stats.to_h.compact
        # Some of the mapping counts are erroneously stored as strings
        stats.select!{ |acronym, count| ontologies_acronym.include?(acronym.to_s) } unless ontologies_acronym.empty?
        stats.transform_values!(&:to_i)
        total_count = stats.values.sum
      end
    rescue StandardError
      LOG.add :error, e.message
    end

    total_count
  end

end

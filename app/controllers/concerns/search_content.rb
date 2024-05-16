module SearchContent
  extend ActiveSupport::Concern

  def search_ontologies(query: '*', groups: [], categories: [], languages: [], private_only: false, formats: [],
                        is_of_type: [], formality_level: [],
                        show_views: false, status: 'alpha,beta,production',
                        page: 1, page_size: 10)

    visibility = private_only ? "private" : 'public'
    qf = [
      "ontology_acronymSuggestEdge^25  ontology_nameSuggestEdge^15 descriptionSuggestEdge^10 ", # start of the word first
      "ontology_acronym_text^15  ontology_name_text^10 description_text^5 "
    ]
    submissions = LinkedData::Client::HTTP.get('search/ontologies',
                                               { query: query.blank? ? "*" : query,
                                                 groups: groups,
                                                 hasDomain: categories,
                                                 hasOntologyLanguage: formats,
                                                 status: status,
                                                 page: page, pagesize: page_size,
                                                 visibility: visibility,
                                                 isOfType: is_of_type,
                                                 hasFormat: formality_level,
                                                 show_views: show_views,
                                                 qf: qf, # custom ranking
                                                 languages: languages }
                                                 .reject { |k, v| v.blank? })

    submissions = submissions.collection

    submissions.map do |os|
      transformed_os = OpenStruct.new
      ontology = OpenStruct.new
      metrics = OpenStruct.new
      os.each_pair do |key, value|
        if key.to_s.start_with?("ontology_")
          ontology[key.to_s.sub("ontology_", "").gsub(/_.*\z/, "")] = value
        elsif key.to_s.start_with?("metrics_")
          metrics[key.to_s.sub("metrics_", "").gsub(/_.*\z/, "")] = value
        elsif key != :links && key != :context
          new_key = key.to_s.gsub(/_.*\z/, "")
          transformed_os[new_key] = value
        end
      end
      transformed_os[:ontology] = ontology unless ontology.to_h.empty?
      transformed_os[:metrics] = metrics unless metrics.to_h.empty?
      transformed_os
    end
  end

  def search_ontologies_content(query:, page: 1, page_size: 10, filter_by_ontologies: [], filter_by_types: [])
    acronyms = filter_by_ontologies
    original_query = query
    types = filter_by_types
    query = query.gsub(':', '\:').gsub('/', '\/') if page.eql?(1)

    qf = [
      "ontology_t^100 resource_id^10",
      "http___www.w3.org_2004_02_skos_core_prefLabel_txt^30",
      "http___www.w3.org_2004_02_skos_core_prefLabel_t^30",
      "http___www.w3.org_2000_01_rdf-schema_label_txt^30",
      "http___www.w3.org_2000_01_rdf-schema_label_t^30",
    ]
    ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym,name,viewOf', also_include_views: true)
    selected_onto = []

    q = query.split(' ').first || ''
    selected_onto += ontologies.select { |x| (acronyms.empty? && x.acronym.downcase.eql?(q.downcase)) || acronyms.include?(x.acronym) }

    selected_onto.uniq!
    [selected_onto.first].compact.each do |o|
      acr = o.acronym
      acronyms << acr
      query.gsub!(/\b#{acr}\b/, "")
      query.gsub!(/\b#{acr.downcase}\b/, "")
      query.gsub!('-', " ")
    end

    query = query
    if query.blank?
      query = "*"
    elsif query.split(' ').size > 1
      query = "^#{query}*"
    else
      query = "*#{query}*"
    end

    results = search_content( q: query, qf: qf.join(' '), page: page, pagesize: page_size, ontologies: acronyms.first, types: types.join(','))
    [search_content_result_to_json(original_query, query, results, ontologies, selected_onto), results.page,results.nextPage, results.totalCount]
  end



  def search_content(params)
    LinkedData::Client::HTTP.get('search/ontologies/content', params)
  end

  private

  def search_content_result_to_json(query, changed_query, results, ontologies, selected_onto = [])
    json = []
    selected_onto = selected_onto.empty? ? ontologies.select { |x| x.name.downcase.include?(query.downcase) || x.acronym.downcase.include?(query.downcase) } : selected_onto

    json += selected_onto.map do |x|
      {
        id: ontology_path(id: x.acronym, p: 'summary'),
        name: x.name,
        acronym: x.acronym,
        type: x.viewOf.blank? ? 'Ontology' : 'Ontology View',
        label: nil
      }
    end

    changed_query.gsub!('*', '')

    json += results.collection.map do |x|
      acronym = x.ontology_t || x.submission_id_t.split('/')[-3]
      next nil unless acronym

      label = nil
      [
        "http___www.w3.org_2000_01_rdf-schema_label_t",
        "http___www.w3.org_2000_01_rdf-schema_label_txt",
        "http___www.w3.org_2004_02_skos_core_prefLabel_t",
        "http___www.w3.org_2004_02_skos_core_prefLabel_txt",
      ].each do |v|
        v = Array(x[v])
        selected_label = v&.select { |p| p.downcase[changed_query.strip.downcase] || changed_query.downcase[p.strip.downcase] }&.first
        label = selected_label if selected_label
        label ||= v&.first
      end


      type = id_type(x.type_t, x.type_txt)
      {
        id: link_by_type(x.resource_id, acronym, type),
        name: x.resource_id,
        acronym: acronym,
        type: type || '',
        label: label
      }
    end.compact

    json
  end

  def supported_types
    %w[Concept Class Ontology ConceptScheme Collection NamedIndividual AnnotationProperty ObjectProperty DatatypeProperty]
  end

  def id_type(type_t, type_txt)

    type = (Array(type_t) + Array(type_txt)).map { |x| helpers.link_last_part(x) }
                                            .select{|x| supported_types.include?(x)}

    type = Array(type).reject { |x| x.eql?("NamedIndividual") } if (Array(type).size > 1)

    type.first
  end

  def link_by_type(id, ontology, type)
    case type
    when 'Concept', 'Class'
      ontology_path(id: ontology, p: 'classes', conceptid: id)
    when 'Ontology'
      ontology_path(id: ontology, p: 'summary')
    when 'ConceptScheme'
      ontology_path(id: ontology, p: 'schemes', schemeid: id)
    when 'Collection'
      ontology_path(id: ontology, p: 'collections', collectionid: id)
    when 'NamedIndividual'
      ontology_path(id: ontology, p: 'instances', instanceid: id)
    when 'AnnotationProperty', 'ObjectProperty', 'DatatypeProperty'
      ontology_path(id: ontology, p: 'properties', propertyid: id)
    else
      "/content_finder?acronym=#{ontology}&uri=#{helpers.escape(id)}&output_format=html"
    end
  end

end


module AnnotatorHelper
  def get_api_params
    api_params = {
      text: remove_special_chars(params[:text]),
      ontologies: params[:ontologies],
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
      lemmatize: params[:lemmatize],
      include: 'prefLabel'
    }
    api_params[:score] = params[:score] unless params[:score].eql?('none')
    api_params
  end

  def find_annotations(uri, api_params, ontologies)
    if request_portals.size == 1
      LinkedData::Client::HTTP.get(uri, api_params)
    else
      filtered_params = {}
      request_portals.each do |portal|
        name = portal.downcase.eql?(portal_name.downcase) ? '' : portal.downcase
        filtered_params[name] = api_params.dup
        filtered_params[name][:ontologies] = api_params[:ontologies].split(',').select do |ont|
          ontology = ontologies.values.find { |o| o.acronym == ont.split('/').last }
          next false if ontology.nil?

          config = ontology_portal_config(ontology.id)&.last || internal_portal_config(ontology.id) || {}
          next false if config.blank?

          portal.downcase.eql?(config[:name].downcase)
        end.map{|x| x.split('/').last }.uniq.join(',')
      end

      LinkedData::Client::Models::Class.federated_get(filtered_params) do |url|
        "#{url}/annotator"
      end
    end
  end

  def annotator_results_table_header
    results_table_header = [
      t('annotator.class'), t('annotator.ontology'), t('annotator.context')
    ]
    if params[:fast_context]
      results_table_header += [t('annotator.negation'), t('annotator.experiencer'), t('annotator.temporality'), t('annotator.certainty')]
    end

    results_table_header.push(t('annotator.score')) unless params[:score].nil? || params[:score].eql?('none')

    results_table_header
  end

  def direct_annotation(annotation)
    ontology = annotation.annotatedClass.links['ontology'] rescue nil

    row = {
      class: annotation_class_info(annotation.annotatedClass),
      ontology: annotation_ontology_info(ontology),
      context: [],
      type: 'direct'
    }
    unless params[:score].eql?('none')
      row[:score] = annotation.score.nil? ? '' : format('%.2f', annotation.score)
    end
    row
  end

  def parent_annotation(parent, annotation)
    row = {
      class: annotation_class_info(parent.annotatedClass),
      ontology: annotation_ontology_info(parent.annotatedClass.links['ontology']),
      context: [{ child: annotation_class_info(annotation.annotatedClass), level: parent.distance }],
      type: 'parent'
    }
    unless params[:score].eql?('none')
      row[:score] = parent.score.nil? ? '' : format('%.2f', parent.score)
    end

    row
  end

  def add_context_annotations(annotation, row)
    annotation.annotations.each do |a|
      row[:context].push(a)
      add_fast_context(row, a)
    end
  end

  def add_fast_context(row, annotation)
    return unless params[:fast_context]
    row[:negation] = annotation.negationContext
    row[:experiencer] = annotation.experiencerContext
    row[:temporality] = annotation.temporalityContext
    row[:certainty] = annotation.certaintyContext
  end

  def annotator_json_button
    regular_button('annotator_json', 'JSON', variant: 'secondary', href: @json_link, size: 'slim', target: '_blank', state: 'regular') do |btn|
      btn.icon_left do
        inline_svg_tag 'json.svg'
      end
    end
  end

  def annotator_rdf_button
    regular_button('annotator_rdf', 'RDF', variant: 'secondary', href: @rdf_link, size: 'slim', target: '_blank', state: 'regular') do |btn|
      btn.icon_left do
        inline_svg_tag 'summary/sparql.svg'
      end
    end
  end

  def annotator_cite_us_button
    regular_button('annotator_cite_us', 'Cite us', variant: 'secondary', href: $CITE_ANNOTATOR, size: 'slim', target: '_blank', state: 'regular') do |btn|
      btn.icon_left do
        inline_svg_tag 'icons/cite.svg'
      end
    end
  end

  def annotator_doc_button
    regular_button('annotator_doc', 'Documentation', variant: 'secondary', href: $ANNOTATOR_DOC, size: 'slim', target: '_blank', state: 'regular') do |btn|
      btn.icon_left do
        inline_svg_tag 'summary/documentation.svg'
      end
    end
  end

  def annotator_class_label_fetcher(cls, ontology)
    config = ontology_portal_config(ontology[:id])&.last || internal_portal_config(ontology[:id]) || {}
    return cls[:id] unless config

    link_to cls[:link] do
      content_tag(:div, class: "class federated-icon-#{config[:name]&.downcase}") do
        federation_link(id: cls[:id], title: cls[:text], color: config[:color], name: config[:name])
      end
    end
  end

  def annotator_external_ontology(ontology)
    config = ontology_portal_config(ontology[:id])&.last || internal_portal_config(ontology[:id]) || {}
    content_tag(:div, class: 'd-flex align-items-center') do
      out = federation_link(id: ontology[:id], title: ontology[:text], color: config[:color], name: config[:name])
      out += portal_button(name: config[:name], color: config[:color], light_color: config[:'light-color'])
      out.html_safe
    end
  end
end
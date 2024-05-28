module MappingsHelper

  # Used to replace the full URI by the prefixed URI
  RELATIONSHIP_PREFIX = {
    "http://www.w3.org/2004/02/skos/core#" => "skos:",
    "http://www.w3.org/2000/01/rdf-schema#" => "rdfs:",
    "http://www.w3.org/2002/07/owl#" => "owl:",
    "http://www.w3.org/1999/02/22-rdf-syntax-ns#" => "rdf:",
    "http://purl.org/linguistics/gold/" => "gold:",
    "http://lemon-model.net/lemon#" => "lemon:"
  }

  INTERPORTAL_HASH = $INTERPORTAL_HASH


  # a little method that returns true if the URIs array contain a gold:translation or gold:freeTranslation
  def translation?(relation_array)
    if relation_array.kind_of?(Array)
      relation_array.map!(&:downcase)
      if relation_array.include? "http://purl.org/linguistics/gold/translation"
        true
      elsif relation_array.include? "http://purl.org/linguistics/gold/freetranslation"
        true
      else
        false
      end
    else
      false
    end
  end

  # a little method that returns the uri with a prefix : http://purl.org/linguistics/gold/translation become gold:translation
  def get_prefixed_uri(uri)
    RELATIONSHIP_PREFIX.each { |k, v| uri.sub!(k, v) }
    return uri
  end

  # method to get (using http) prefLabel for interportal classes
  # Using bp_ajax_controller.ajax_process_interportal_cls will try to resolve class labels.
  def ajax_to_inter_portal_cls(cls)
    inter_portal_acronym = get_inter_portal_acronym(cls.links["ui"])
    href_cls = " href='#{cls.links["ui"]}' "
    if inter_portal_acronym
      data_cls = " data-cls='#{cls.links["self"]}?apikey=' "
      portal_cls = " portal-cls='#{inter_portal_acronym}' "
      raw("<a class='interportalcls4ajax' #{data_cls} #{portal_cls} #{href_cls} target='_blank'>#{cls.id}</a>")
    else
      raw("<a #{href_cls} target='_blank'>#{cls.id}</a>")
    end

  end

  def ajax_to_internal_cls(cls)
    link_to("#{cls.id}<span href='/ajax/classes/label?ontology=#{cls.links["ontology"]}&concept=#{escape(cls.id)}' class='get_via_ajax'></span>".html_safe,
            ontology_path(cls.explore.ontology.acronym, p: 'classes', conceptid: cls.id))
  end

  # to get the apikey from the interportal instance of the interportal class.
  # The best way to know from which interportal instance the class came is to compare the UI url
  def get_inter_portal_acronym(class_ui_url)
    if !INTERPORTAL_HASH.nil?
      INTERPORTAL_HASH.each do |key, value|
        if class_ui_url.start_with?(value["ui"])
          return key
        else
          return nil
        end
      end
    end
  end

  # method to extract the prefLabel from the external class URI
  def get_label_for_external_cls(class_uri)
    if class_uri.include? "#"
      prefLabel = class_uri.split("#")[-1]
    else
      prefLabel = class_uri.split("/")[-1]
    end
    return prefLabel
  end

  def ajax_to_external_cls(cls)
    raw("<a href='#{cls.links['self']}' target='_blank'>#{get_label_for_external_cls(cls.id)}</a>")
  end

  # Replace the inter_portal mapping ontology URI (that link to the API) by the link to the ontology in the UI
  def get_inter_portal_ui_link(uri, process_name)
    process_name = '' if process_name.nil?
    interportal_acronym = process_name.split(" ")[2]
    if interportal_acronym.nil? || interportal_acronym.empty?
      uri
    else
      uri.sub!(INTERPORTAL_HASH[interportal_acronym]["api"], INTERPORTAL_HASH[interportal_acronym]["ui"])
    end
  end

  def internal_mapping?(cls)
    cls.links['self'].to_s.start_with?(LinkedData::Client.settings.rest_url) || ($LOCAL_IP.present? && cls.links['self'].to_s.include?($LOCAL_IP))
  end

  def inter_portal_mapping?(cls)
    !internal_mapping?(cls) && cls.links.has_key?("ui")
  end

  def get_mappings_target_params
    mapping_type = Array(params[:mapping_type]).first
    external = true
    case mapping_type
    when 'interportal'
      ontology_to = "#{params[:map_to_interportal]}/ontologies/#{params[:map_to_interportal_ontology]}"
      concept_to_id = params[:map_to_interportal_class]
    when 'external'
      ontology_to = params[:map_to_external_ontology]
      concept_to_id = params[:map_to_external_class]
    else
      ontology_to = params[:map_to_bioportal_ontology_id]
      concept_to_id = params[:map_to_bioportal_full_id]
      external = false
    end
    [ontology_to, concept_to_id, external]
  end

  def set_mapping_target(concept_to_id:, ontology_to:, mapping_type: )
    case mapping_type
    when 'interportal'
      @map_to_interportal, @map_to_interportal_ontology = ontology_to.match(%r{(.*)/ontologies/(.*)}).to_a[1..]
      @map_to_interportal_class = concept_to_id
    when 'external'
      @map_to_external_ontology = ontology_to
      @map_to_external_class = concept_to_id
    else
      @map_to_bioportal_ontology_id = ontology_to
      @map_to_bioportal_full_id = concept_to_id
    end
  end

  def get_mappings_target
    ontology_to, concept_to_id, external_mapping = get_mappings_target_params
    target = ''
    if external_mapping
      target_ontology = ontology_to
      target = concept_to_id
    else
      if helpers.uri?(ontology_to)
        target_ontology = LinkedData::Client::Models::Ontology.find(ontology_to)
      else
        target_ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ontology_to).first
      end
      if target_ontology
        target = target_ontology.explore.single_class(concept_to_id).id
        target_ontology = target_ontology.id
      end
    end
    [target_ontology, target, external_mapping]
  end

  def type?(type)
    @mapping_type.nil? && type.eql?('internal') || @mapping_type.eql?(type)
  end

  def concept_mappings_loader(ontology_acronym: ,concept_id: )
    content_tag(:span, id: 'mapping_count') do
      concat(content_tag(:div, class: 'concepts-mapping-count ml-1 mr-1') do
        render(TurboFrameComponent.new(
          id: 'mapping_count',
          src: "/ajax/mappings/get_concept_table?ontologyid=#{ontology_acronym}&conceptid=#{CGI.escape(concept_id)}",
          loading: 'lazy'
        )) do |t|
          concat(t.loader { render(LoaderComponent.new(small: true)) })
        end
      end)
    end
  end

  def client_filled_modal
    link_to_modal "", ""
  end

  def mappings_bubble_view_legend
    content_tag(:div, class: 'mappings-bubble-view-legend') do
      mappings_legend_section(t('mappings.bubble_view_legend.bubble_size'), t('mappings.bubble_view_legend.bubble_size_desc'), 'mappings-bubble-size-legend') +
        mappings_legend_section(
          t('mappings.bubble_view_legend.color_degree'),t('mappings.bubble_view_legend.color_degree_desc'),'mappings-bubble-color-legend') +
        content_tag(:div, class: 'content-container') do
          content_tag(:div, class: 'bubble-view-legend-item') do
            content_tag(:div, class: 'title') do
              content_tag(:div, t('mappings.bubble_view_legend.yellow_bubble'), class: 'd-inline') + content_tag(:span, t('mappings.bubble_view_legend.selected_bubble'))
            end +
              content_tag(:div, class: "mappings-bubble-size-legend d-flex justify-content-center") do
                content_tag(:div, '', class: "bubble yellow")
              end
          end
        end
    end
  end

  def mappings_legend_section(title_text, description_text, css_class)
    content_tag(:div, class: 'content-container') do
      content_tag(:div, class: 'bubble-view-legend-item') do
        content_tag(:div, class: 'title') do
          content_tag(:div, "#{title_text} ", class: 'd-inline') +
            content_tag(:span, description_text)
        end +
          mappings_legend(css_class)
      end
    end
  end

  def mappings_legend(css_class)
    content_tag(:div, class: css_class) do
      content_tag(:div, t('mappings.bubble_view_legend.less_mappings'), class: 'mappings-legend-text') +
        (1..6).map { |i| content_tag(:div, "", class: "bubble bubble#{i}") }.join.html_safe +
        content_tag(:div, t('mappings.bubble_view_legend.more_mappings'), class: 'mappings-legend-text')
    end
  end
end

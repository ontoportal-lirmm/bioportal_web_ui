module SchemesHelper
  include UrlsHelper

  def get_schemes(ontology)
    ontology.explore.schemes(language: request_lang)
  end

  def get_scheme(ontology, scheme_uri)
    ontology.explore.schemes({ include: 'all',  language: request_lang}, scheme_uri)
  end

  def get_scheme_label(scheme)
    return '' if scheme.nil?

    if scheme['prefLabel'].nil? || scheme['prefLabel'].empty?
      extract_label_from(scheme['@id']).html_safe if scheme['@id']
    else
      scheme['prefLabel']
    end
  end

  def get_schemes_labels(schemes, main_uri)

    selected_label = nil
    schemes_labels = []
    schemes.each do  |x|
      id = x['@id']
      label = select_language_label(get_scheme_label(x))
      if id.eql? main_uri
        label[1] = "#{label[1]} (main)" unless label[0].empty?
        selected_label = { 'prefLabel' => label, '@id' => id }
      else
        schemes_labels.append( { 'prefLabel' => label, '@id' => id })
      end
    end

    schemes_labels = sorted_labels(schemes_labels)
    schemes_labels.unshift selected_label if selected_label
    [schemes_labels, selected_label]
  end

  def concept_label_to_show(submission: @submission_latest)
    submission&.hasOntologyLanguage == 'SKOS' ? 'concepts' : 'classes'
  end

  def section_name(section)
    section = concept_label_to_show(submission: @submission_latest || @submission) if section.eql?('classes')
    t("ontology_details.sections.#{section}")
  end

  def scheme_path(ontology_id: @ontology.acronym, scheme_id: '', language: request_lang)
    "/ontologies/#{ontology_id}/schemes/show?id=#{escape(scheme_id)}&lang=#{language}"
  end

  def no_main_scheme?
    @submission.URI.nil? || @submission.URI.empty?
  end

  def no_schemes?
    @schemes.nil? || @schemes.empty?
  end

  def no_main_scheme_alert
    render Display::AlertComponent.new do
      t('schemes.no_main_scheme_alert')
    end
  end

  def no_schemes_alert
    render Display::AlertComponent.new do
      t('schemes.no_schemes_alert', acronym: @ontology.acronym)
    end
  end

  def schemes_data
    schemes_labels, main_scheme = get_schemes_labels(@schemes,@submission.URI)
    selected_scheme = @schemes.select{ |s| params[:concept_schemes]&.split(',')&.include?(s['@id']) }
    selected_scheme = selected_scheme.empty? ? [main_scheme] : selected_scheme
    [schemes_labels, main_scheme, selected_scheme]
  end

  def schemes_tree(schemes_labels, main_scheme_label, selected_scheme_id, submission: @submission_latest)
    selected_scheme = nil
    schemes = sorted_labels(schemes_labels).map do |s|
      next nil unless main_scheme_label.nil? || s['prefLabel'] != main_scheme_label['prefLabel']
      scheme = OpenStruct.new(s)
      scheme.prefLabel = Array(get_scheme_label(s)).last
      scheme.id = scheme['@id']
      selected_scheme = scheme if  scheme.id.eql?(selected_scheme_id)
      scheme
    end.compact

    main_scheme = nil
    if main_scheme_label.nil?
      children = schemes
    else
      main_scheme = OpenStruct.new(main_scheme_label)
      main_scheme.prefLabel = Array(get_scheme_label(main_scheme_label)).last
      main_scheme.children = schemes
      main_scheme.id = main_scheme['@id']
      main_scheme['expanded?'] = true
      main_scheme['hasChildren'] = true
      children = [main_scheme]
    end
    root = OpenStruct.new
    root.children = children
    selected_scheme = selected_scheme || main_scheme || root.children.first
    tree_component(root, selected_scheme, target_frame: 'scheme', auto_click: false, submission: submission) do |child|
      href = scheme_path(scheme_id: child['@id'], ontology_id: @ontology.acronym, language: request_lang)
      data = { schemeid: child['@id']}
      ["#", data, href]
    end
  end
end

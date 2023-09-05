module SchemesHelper

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

  def scheme_path(scheme_id = '', language = '')
    "/ontologies/#{@ontology.acronym}/schemes/show_scheme?id=#{escape(scheme_id)}&lang=#{language}"
  end

  def no_main_scheme?
    @submission.URI.nil? || @submission.URI.empty?
  end

  def no_schemes?
    @schemes.nil? || @schemes.empty?
  end

  def no_main_scheme_alert
    render Display::AlertComponent.new do
      'no main scheme defined in the URI attribute'
    end
  end
  def no_schemes_alert
    render Display::AlertComponent.new do
      "#{@ontology.acronym} does not contain schemes (skos:ConceptScheme)"
    end
  end

  def schemes_data
    schemes_labels, main_scheme = get_schemes_labels(@schemes,@submission.URI)
    selected_scheme = @schemes.select{ |s| params[:concept_schemes]&.split(',')&.include?(s['@id']) }
    selected_scheme = selected_scheme.empty? ? [main_scheme] : selected_scheme
    [schemes_labels, main_scheme, selected_scheme]
  end

  def tree_link_to_schemes(schemes_labels, main_scheme_label, selected_scheme_id)
    out = ''

    sorted_labels(schemes_labels).each do |s|
      next unless main_scheme_label.nil? || s['prefLabel'] != main_scheme_label['prefLabel']

      out  << <<-EOS
            <li class="doc">
              #{link_to_scheme(s, selected_scheme_id)}
            </li>
      EOS
    end
    out
  end
  def link_to_scheme(scheme, selected_scheme_id)
    pref_label_lang, pref_label_html = get_scheme_label(scheme)
    tooltip  = pref_label_lang.to_s.eql?('@none') ? '' :  "data-controller='tooltip' data-tooltip-position-value='right' title='#{pref_label_lang.upcase}'"
    <<-EOS
          <a id="#{scheme['@id']}" href="#{scheme_path(scheme['@id'], request_lang)}" 
            data-turbo="true" data-turbo-frame="scheme" data-schemeid="#{scheme['@id']}"
           #{tooltip}
            class="#{selected_scheme_id.eql?(scheme['@id']) ? 'active' : nil}">
              #{pref_label_html}
          </a>
    EOS
  end
end


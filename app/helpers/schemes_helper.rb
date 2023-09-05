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
      label = get_scheme_label(x)
      if id.eql? main_uri
        label = "#{label} (main)" unless label.empty?
        selected_label = { 'prefLabel' => label, '@id' => id }
      else
        schemes_labels.append( { 'prefLabel' => label, '@id' => id })
      end
    end
    schemes_labels.sort_by! { |s|  s['prefLabel']}

    if selected_label
      schemes_labels.unshift selected_label
    end
    [schemes_labels, selected_label]
  end

  def concept_label_to_show(submission: @submission_latest)
    submission&.hasOntologyLanguage == 'SKOS' ? 'concepts' : 'classes'
  end

  def section_name(section)
    section = concept_label_to_show(submission: @submission_latest || @submission) if section.eql?('classes')

    t("ontology_details.sections.#{section}")
  end

  def scheme_path(scheme_id = '')
    "/ontologies/#{@ontology.acronym}/schemes/show_scheme?id=#{escape(scheme_id)}"
  end

  def no_main_scheme?
    @submission.URI.nil? || @submission.URI.empty?
  end

  def no_schemes?
    @schemes.nil? || @schemes.empty?
  end

  def no_main_scheme_alert
    render AlertMessageComponent.new(id: 'main-scheme-empty-info') do
      'no main scheme defined in the URI attribute'
    end
  end
  def no_schemes_alert
    render AlertMessageComponent.new(id: 'schemes-empty-info') do
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
    schemes_labels.sort_by { |s| [s['prefLabel']] }.each do |s|
      next unless main_scheme_label.nil? || s['prefLabel'] != main_scheme_label['prefLabel']

      li = <<-EOS
        <li class="doc">
          <a id="#{s['@id']}" href="#{scheme_path(s['@id'])}" 
            data-turbo="true" data-turbo-frame="scheme" data-schemeid="#{s['@id']}"
            class="#{selected_scheme_id.eql?(s['@id']) ? 'active' : nil}">
              #{get_scheme_label(s)}
          </a>
        </li>
      EOS
      out << li
    end
    out
  end
end


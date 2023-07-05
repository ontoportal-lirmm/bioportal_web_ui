module OntologiesHelper

  REST_URI = $REST_URL
  API_KEY = $API_KEY
  LANGUAGE_FILTERABLE_SECTIONS  = %w[classes schemes collections instances]



  def additional_details
    return "" if $ADDITIONAL_ONTOLOGY_DETAILS.nil? || $ADDITIONAL_ONTOLOGY_DETAILS[@ontology.acronym].nil?
    details = $ADDITIONAL_ONTOLOGY_DETAILS[@ontology.acronym]
    html = []
    details.each do |title, value|
      html << content_tag(:tr) do
        html << content_tag(:td, title)
        html << content_tag(:td, raw(value))
      end
    end
    html.join('')
  end

  # Display data catalog metadata under visits (in _metadata.html.haml)
  def display_data_catalog(sub)
    if !sub.send("includedInDataCatalog").nil? && sub.send("includedInDataCatalog").any?
      # Buttons for data catalogs
      return content_tag(:section, { :class => "ont-metadata-card ont-included-in-data-catalog-card" }) do
        concat(content_tag(:div, { :class => "ont-section-toolbar" }) do
          concat(content_tag(:header, "includedInDataCatalog", { :class => "pb-2 font-weight-bold" }))
        end)
        concat(content_tag(:div, { :class => "" }) do
          sub.send("includedInDataCatalog").each do |catalog|
            catalog_btn_label = catalog
            $DATA_CATALOG_VALUES.each do |cat_uri, cat_label|
              if catalog[cat_uri]
                catalog_btn_label = cat_label
                break
              end
            end
            concat(content_tag(:a, catalog_btn_label, { :class => "btn btn-primary", :href => catalog, :target => "_blank" }))
          end
        end)
      end
    else
       ""
    end
  end

  # Display data catalog metadata under visits (in _metadata.html.haml)
  def display_logo(sub)
    logo_attributes = ["logo", "depiction"]
    logo_html = ""
    logo_attributes.each do |metadata|
      if !sub.send(metadata).nil?
        puts sub.send(metadata)
        logo_html.concat(content_tag(:section, { :class => "ont-metadata-card ont-logo-depiction-card" }) do
          concat(content_tag(:div, { :class => "ont-section-toolbar" }) do
            concat(content_tag(:header, metadata.capitalize, { :class => "pb-2 font-weight-bold" }))
          end)
          concat(content_tag(:div, { :class => "" }) do
            concat(content_tag(:a, { :href => sub.send(metadata), :title => sub.send(metadata),
                                     :target => "_blank", :style => "border-width:0;" }) do

              concat(content_tag(:img, "", { :title => sub.send(metadata),
                                             :style => "border-width:0;max-width: 100%;", :src => sub.send(metadata).to_s }))
            end)
          end)
        end)
      end
    end
    return logo_html
  end



  def count_links(ont_acronym, page_name = 'summary', count = 0)
    ont_url = "/ontologies/#{ont_acronym}"
    if count.nil? || count.zero?
      return '0'
    else
      return "<a href='#{ont_url}/?p=#{page_name}'>#{number_with_delimiter(count, delimiter: ',')}</a>"
    end
  end

  def classes_link(ontology, count)
    return '0' if ontology.summaryOnly || count.nil? || count.zero?

    count_links(ontology.ontology.acronym, 'classes', count)
  end

  # Creates a link based on the status of an ontology submission
  def download_link(submission, ontology = nil)
    ontology ||= @ontology
    links = []
    if ontology.summaryOnly
      if submission.homepage.nil?
        links << {href: '', label:'N/A - metadata only'}
      else
        uri = submission.homepage
        links << {href: uri, label:'Home Page'}
      end
    else
      uri = submission.id + "/download?apikey=#{get_apikey}"
      links << {href: uri, label:submission.pretty_format}
      latest = ontology.explore.latest_submission({ include_status: 'ready' })
      if latest && latest.submissionId == submission.submissionId
        links << {href: "#{ontology.id}/download?apikey=#{get_apikey}&download_format=csv", label:"CSV"}
        if !latest.hasOntologyLanguage.eql?('UMLS')
          links << {href: "#{ontology.id}/download?apikey=#{get_apikey}&download_format=rdf", label:"RDF/XML"}
        end
      end
      unless submission.diffFilePath.nil?
        uri = submission.id + "/download_diff?apikey=#{get_apikey}"
        links << {href: uri, label:"DIFF"}
      end
    end
    links
  end

  def link?(string)
    string.start_with?('http://') || string.start_with?('https://')
  end

  def mappings_link(ontology, count)
    return '0' if ontology.summaryOnly || count.nil? || count.zero?

    count_links(ontology.ontology.acronym, 'mappings', count)
  end

  def notes_link(ontology, count)
    count_links(ontology.ontology.acronym, 'notes', count)
  end

  # Creates a link based on the status of an ontology submission
  def status_link(submission, latest = false, target = '')
    version_text = submission.version.nil? || submission.version.to_s.length == 0 ? 'unknown' : submission.version.to_s
    status_text = " <span class='ontology_submission_status'>" + submission_status2string(submission) + '</span>'
    if submission.ontology.summaryOnly || latest == false
      version_link = version_text
    else
      version_link = "<a href='/ontologies/#{submission.ontology.acronym}?p=classes' #{target.empty? ? '' : "target='#{target}'"}>#{version_text}</a>"
    end
    version_link + status_text
  end

  def submission_status2string(sub)
    # Massage the submission status into a UI string
    # submission status values, from:
    # https://github.com/ncbo/ontologies_linked_data/blob/master/lib/ontologies_linked_data/models/submission_status.rb
    # "UPLOADED", "RDF", "RDF_LABELS", "INDEXED", "METRICS", "ANNOTATOR", "ARCHIVED"  and 'ERROR_*' for each.
    # Strip the URI prefix from the status codes (works even if they are not URIs)
    # The order of the codes must be assumed to be random, it is not an entirely
    # predictable sequence of ontology processing stages.
    codes = sub.submissionStatus.map { |s| s.split('/').last }
    errors = codes.select { |c| c.start_with? 'ERROR' }.map { |c| c.gsub("_", " ").split(/(\W)/).map(&:capitalize).join }.compact
    status = []
    status.push('Parsed') if (codes.include? 'RDF') && (codes.include? 'RDF_LABELS')
    # The order of this array imposes an oder on the UI status code string
    status_list = ['INDEXED', 'METRICS', 'ANNOTATOR', 'ARCHIVED']
    status_list.insert(0, 'UPLOADED') unless status.include?('Parsed')
    status_list.each do |c|
      status.push(c.capitalize) if codes.include? c
    end
    status.concat errors
    return '' if status.empty?

    '(' + status.join(', ') + ')'
  end

  # Link for private/public/licensed ontologies
  def visibility_link(ontology)
    ont_url = "/ontologies/#{ontology.acronym}" # 'ontology' is NOT a submission here
    page_name = 'summary'  # default ontology page view for visibility link
    link_name = 'Public'   # default ontology visibility
    if ontology.summaryOnly
      link_name = 'Summary Only'
    elsif ontology.private?
      link_name = 'Private'
    elsif ontology.licensed?
      link_name = 'Licensed'
    end
    "<a href='#{ont_url}/?p=#{page_name}'>#{link_name}</a>"
  end

  def show_category_name(domain)
    acronym = domain.split('/').last.upcase
    category = LinkedData::Client::Models::Category.find_by_acronym(acronym).first
    category ? category.name : acronym
  end

  def visits_data(ontology = nil)
    ontology ||= @ontology

    return nil unless @analytics && @analytics[ontology.acronym.to_sym]

    return @visits_data if @visits_data

    visits_data = { visits: [], labels: [] }
    years = @analytics[ontology.acronym.to_sym].to_h.keys.map { |e| e.to_s.to_i }.select { |e| e > 0 }.sort
    now = Time.now
    years.each do |year|
      months = @analytics[ontology.acronym.to_sym].to_h[year.to_s.to_sym].to_h.keys.map { |e| e.to_s.to_i }.select { |e| e > 0 }.sort
      months.each do |month|
        # No good data prior to Oct 2013
        next if now.year == year && now.month <= month || (year == 2013 && month < 10)

        visits_data[:visits] << @analytics[ontology.acronym.to_sym].to_h[year.to_s.to_sym][month.to_s.to_sym]
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    @visits_data = visits_data
  end

  def acronyms(ontologies)
    ontologies.present? ? ontologies.map { |ont| ont.acronym } : []
  end

  def change_requests_enabled?(ontology_acronym)
    return false unless Rails.configuration.change_request[:ontologies].present?

    Rails.configuration.change_request[:ontologies].include? ontology_acronym.to_sym
  end
  def current_section
    (params[:p]) ? params[:p] : 'summary'
  end

  def link_to_section(section_title)
    link_to(section_name(section_title) , ontology_path(@ontology.acronym, p: section_title),
            id: "ont-#{section_title}-tab",
            class: "#{selected_section?(section_title) ? 'active show' : ''}")

  end

  def selected_section?(section_title)
    current_section.eql?(section_title)
  end

  def ontology_data_sections
    LANGUAGE_FILTERABLE_SECTIONS
  end

  def ontology_data_section?(section_title = current_section)
    ontology_data_sections.include?(section_title)
  end

  def section_data(section_title)
    if ontology_data_section?(section_title)
      url_value = selected_section?(section_title) ? request.fullpath : "/ontologies/#{@ontology.acronym}?p=#{section_title}"
      { controller: "history turbo-frame" , 'turbo-frame-url-value': url_value ,action: "lang_changed->history#updateURL lang_changed->turbo-frame#updateFrame" }
    else
      {}
    end
  end

  def lazy_load_section(section_title, &block)
    if current_section.eql?(section_title)
      block.call
    else
      render TurboFrameComponent.new(id: section_title, src: "/ontologies/#{@ontology.acronym}?p=#{section_title}", target: '_top', data: {"turbo-frame-target": "frame"} )
    end
  end

  def visits_chart_dataset(visits_data)
    [{
       label: 'Visits',
       data: visits_data,
       backgroundColor: 'rgba(151, 187, 205, 0.2)',
       borderColor: 'rgba(151, 187, 205, 1)',
       pointBorderColor: 'rgba(151, 187, 205, 1)',
       pointBackgroundColor: 'rgba(151, 187, 205, 1)',
     }].to_json
  end

  def sections_to_show
    sections = ['summary']

    unless @ontology.summaryOnly || @submission_latest.nil?
      sections += %w[classes properties notes mappings]
      sections += %w[schemes collections] if skos?
      sections += %w[instances] unless skos?
      sections += %w[widgets]
    end
    sections
  end


  def language_selector_tag(name)
    languages = languages_options

    if languages.empty?
      content_tag(:div ,data: {'ontology-viewer-tabs-target': 'languageSelector'}, style: "visibility: #{ontology_data_section? ? 'visible' : 'hidden'} ; margin-bottom: -1px;") do
        render EditSubmissionAttributeButtonComponent.new(acronym: @ontology.acronym, submission_id: @submission_latest.submissionId, attribute: :naturalLanguage) do
          concat "Enable multilingual display "
          concat content_tag(:i , "", class: "fas fa-lg fa-question-circle")
        end
      end
    else
      select_tag name, languages_options, class: 'custom-select', disabled: !ontology_data_section?, style: "visibility: #{ontology_data_section? ? 'visible' : 'hidden'}; margin-bottom: -10px;", data: {'ontology-viewer-tabs-target': 'languageSelector'}
    end
  end

  def language_selector_hidden_tag(section)
    hidden_field_tag "language_selector_hidden_#{section}", '',
                     data: { controller: "language-change", 'language-change-section-value': section, action: "change->language-change#dispatchLangChangeEvent"}
  end

  def languages_options(submission =  @submission || @submission_latest)
    current_lang = request_lang
    submission_lang = submission_languages(submission)
    # Transform each language into a select option
    submission_lang = submission_lang.map do |lang|
      lang = lang.split('/').last.upcase
      [lang, lang, { selected: lang.eql?(current_lang) }]
    end
    options_for_select(submission_lang)
  end

  def dispaly_complex_text(definitions)
    html = ""
    definitions.each do |definition|
      if definition.is_a?(String)
        html+= "<p>" + definition + "</p>"
      elsif definition.respond_to?(:uri) && definition.uri
        html+= "<p>" + definition.uri + "</p>"
      end
    end
    return html.html_safe
  end


  def count_subscriptions(ontology_id)
    users = LinkedData::Client::Models::User.all(include: 'subscription', display_context: false, display_links: false )
    users.select{ |u| u.subscription.find{ |s| s.ontology.eql?(ontology_id)} }.count
  end
  private

  def submission_languages(submission = @submission)
    submission.naturalLanguage.map { |natural_language| natural_language["iso639"] && natural_language.split('/').last }.compact
  end
end


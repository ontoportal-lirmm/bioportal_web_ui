require 'iso-639'
module OntologiesHelper

  REST_URI = $REST_URL
  API_KEY = $API_KEY
  LANGUAGE_FILTERABLE_SECTIONS = %w[classes schemes collections instances]


  def ontology_retired?(submission)
    submission[:status].to_s.eql?('retired') || submission[:deprecated].to_s.eql?('true')
  end
  def ontology_license_badge(acronym, submission = @submission_latest)
    return if submission.nil?

    no_license = submission.hasLicense.blank?
    render ChipButtonComponent.new(class: "chip_button_small #{no_license && 'disabled-link'}", type: no_license ? 'static' : 'clickable') do
      if no_license
        content_tag(:span) do
          content_tag(:span, "No license", class: "mx-1") + inline_svg_tag('icons/law.svg', width: "15px")
        end
      else
        link_to_modal(nil, "/ajax/submission/show_licenses/#{acronym}",data: { show_modal_title_value: "Additional license a access rights information"}) do
          content_tag(:span, "View license", class: "mx-1") + inline_svg_tag('icons/law.svg')
        end
      end

    end
  end
  def ontology_retired_badge(submission, small: false, clickable: true)
    return if submission.nil? || !ontology_retired?(submission)
    text_color = submission[:status].to_s.eql?('retired') ? 'text-danger bg-danger-light' : 'text-warning bg-warning-light'
    text_content = submission[:status].to_s.eql?('retired') ?  'Retired' : 'Deprecated'
    style = "#{text_color} #{small && 'chip_button_small'}"
    render ChipButtonComponent.new(class:  "#{style} mr-1", text: text_content, type: clickable ? 'clickable' : 'static')
  end

  def ontology_alternative_names(submission = @submission_latest)
    alt_labels = (Array(submission&.alternative) + Array(submission&.hiddenLabel))
    return unless alt_labels.present?

    content_tag(:div, class: 'creation_text') do
      concat("It can also be referred to as ")
      concat(content_tag(:span, class: 'date_creation_text') do
        if alt_labels.length > 1
          concat("#{alt_labels[0..-2].join(', ')} or #{alt_labels.last}.")
        else
          concat("#{alt_labels.first}.")
        end
      end)
    end
  end
  def private_ontology_icon(is_private)
    raw(content_tag(:i, '', class: 'fas fa-key', title: "Private Ontology")) if is_private
  end
  def browse_filter_section_label(key)
    labels = {
      hasFormalityLevel: 'Formality levels',
      isOfType: 'Ontology types',
      naturalLanguage: 'Natural languages'
    }

    labels[key] || key.to_s.underscore.humanize.capitalize
  end

  def browser_counter_loader
    content_tag(:div, class: "browse-desc-text", style: "margin-bottom: 15px;") do
      content_tag(:div, class: "d-flex align-items-center") do
        str = content_tag(:span, "Showing")
        str += content_tag(:span, "", class: "p-1 p-2", style: "color: #a7a7a7;") do
          render LoaderComponent.new(small: true)
        end
        str
      end
    end
  end

  def ontologies_browse_skeleton(pagesize = 5)
    pagesize.times do
      concat render OntologyBrowseCardComponent.new
    end
  end

  def ontologies_filter_url(filters, page: 1, count: false)
    url = 'ontologies_filter?'
    url += "page=#{page}" if page
    url += "count=#{page}" if count
    if filters
      filters_str = filters.reject { |k, v| v.nil? || (k.eql?(:sort_by) && count) }
                           .map { |k, v| "#{k}=#{v}" }.join('&')
      url += "&#{filters_str}"
    end
    url
  end

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
  def display_data_catalog(value)
    if !value.nil? && value.any?
      # Buttons for data catalogs
      content_tag(:div, { :class => "" }) do

      end
    else
      ""
    end
  end

  def agent?(sub_metadata, attr)
    metadata = sub_metadata.select { |x| x['@id'][attr] }.first
    metadata && Array(metadata['enforce']).include?('Agent')
  end

  def display_contact(contacts)
    contacts.map { |c| "#{c.name.humanize} at #{c.email}" if c.member?(:name) && c.member?(:email) }&.join(", ")
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
        links << { href: '', label: 'N/A - metadata only' }
      else
        uri = submission.homepage
        links << { href: uri, label: 'Home Page' }
      end
    else
      uri = submission.id + "/download?apikey=#{get_apikey}"
      links << { href: uri, label: submission.pretty_format }
      latest = ontology.explore.latest_submission({ include_status: 'ready' })
      if latest && latest.submissionId == submission.submissionId
        links << { href: "#{ontology.id}/download?apikey=#{get_apikey}&download_format=csv", label: "CSV" }
        if !latest.hasOntologyLanguage.eql?('UMLS')
          links << { href: "#{ontology.id}/download?apikey=#{get_apikey}&download_format=rdf", label: "RDF/XML" }
        end
      end
      unless submission.diffFilePath.nil?
        uri = submission.id + "/download_diff?apikey=#{get_apikey}"
        links << { href: uri, label: "DIFF" }
      end
    end
    links
  end

  def link?(string)
    string.to_s.start_with?('http://') || string.to_s.start_with?('https://')
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


  def submission_status2string(data)
    return '' if data[:submissionStatus].nil?

    # Massage the submission status into a UI string
    # submission status values, from:
    # https://github.com/ncbo/ontologies_linked_data/blob/master/lib/ontologies_linked_data/models/submission_status.rb
    # "UPLOADED", "RDF", "RDF_LABELS", "INDEXED", "METRICS", "ANNOTATOR", "ARCHIVED"  and 'ERROR_*' for each.
    # Strip the URI prefix from the status codes (works even if they are not URIs)
    # The order of the codes must be assumed to be random, it is not an entirely
    # predictable sequence of ontology processing stages.
    codes = data[:submissionStatus].map { |s| s.split('/').last }
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

  def status_string(data)
    return '' unless data.present? && data[:submissionStatus].present?

    submission_status2string(data)
  end

  def submission_status_ok?(status)
    status.include?('Parsed') && !status.include?('Error')
  end

  def submission_status_error?(status)
    !status.include?('Parsed') && status.include?('Error')
  end

  def submission_status_warning?(status)
    status.include?('Parsed') && status.include?('Error')
  end

  def submission_status_icons(status)
    if submission_status_ok?(status)
      "success-icon.svg"
    elsif submission_status_error?(status)
      'error-icon.svg'
    elsif status == '(Archived)'
      'archive.svg'
    elsif submission_status_warning?(status)
      "alert-triangle.svg"
    else
      "info.svg"
    end
  end

  # Link for private/public/licensed ontologies
  def visibility_link(ontology)
    ont_url = "/ontologies/#{ontology.acronym}" # 'ontology' is NOT a submission here
    page_name = 'summary' # default ontology page view for visibility link
    link_name = 'Public' # default ontology visibility
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
    category ? category.name : acronym.titleize
  end

  def show_group_name(domain)
    acronym = domain.split('/').last.upcase
    category = LinkedData::Client::Models::Group.find_by_acronym(acronym).first
    category ? category.name : acronym.titleize
  end

  def show_group_name(domain)
    acronym = domain.split('/').last.upcase
    category = LinkedData::Client::Models::Group.find_by_acronym(acronym).first
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
    link_to(section_name(section_title), ontology_path(@ontology.acronym, p: section_title),
            id: "ont-#{section_title}-tab", class: "nav-link #{selected_section?(section_title) ? 'active show' : ''}",
            data: { action: 'click->ontology-viewer-tabs#selectTab',
                    toggle: "tab", target: "#ont_#{section_title}_content", 'bp-ont-page': section_title,
                    'bp-ont-page-name': ontology_viewer_page_name(@ontology.name, @concept&.prefLabel || '', section_title) })
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
      { controller: "history turbo-frame", 'turbo-frame-url-value': url_value, action: "lang_changed->history#updateURL lang_changed->turbo-frame#updateFrame" }
    else
      {}
    end
  end

  def lazy_load_section(section_title, &block)
    if current_section.eql?(section_title)
      block.call
    else
      render TurboFrameComponent.new(id: section_title, src: "/ontologies/#{@ontology.acronym}?p=#{section_title}",
                                     loading: Rails.env.development?  ? "lazy" : "eager",
                                     target: '_top', data: { "turbo-frame-target": "frame" })
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

  def submission_ready?(submission)
    Array(submission&.submissionStatus).include?('RDF')
  end

  def sections_to_show
    sections = ['summary']

    if !@ontology.summaryOnly && submission_ready?(@submission_latest)
      sections += ['classes']
      sections += %w[properties]
      sections += %w[schemes collections] if skos?
      sections += %w[instances] unless skos?
      sections += %w[notes mappings widgets]
    end
    sections
  end

  def not_ready_submission_alert(ontology: @ontology, submission: @submission)
    if ontology.admin?(session[:user])
      status = status_string(submission)
      type = nil
      message = nil
      if submission_status_error?(status)
        type = 'danger'
        message = "The ontology processing failed, with the current statuses: #{status}"
      elsif submission_status_warning?(status)
        message = "The ontology parsing succeeded, but some processing steps failed, here are the current statuses: #{status}"
        type = 'warning'

      elsif !submission_ready?(submission)
        type = 'info'
        if submission.nil?
          message = "Upload an ontology. Sections such as #{ontology_data_sections.join(', ')} will be available once done."
        else
          message = "The ontology is processing. Sections such as #{ontology_data_sections.join(', ')} will be available once processing is complete."
        end
      end
      render Display::AlertComponent.new(message: message, type: type) if type
    end
  end

  def dispaly_complex_text(definitions)
    html = ""
    definitions.each do |definition|
      if definition.is_a?(String)
        html += '<p class="prefLabel">' + definition + '</p>'
      elsif definition.respond_to?(:uri) && definition.uri
        html +=  '<p>' + definition.uri + '</p>'
      end
    end
    return html.html_safe
  end

  def language_selector_tag(name)
    languages = languages_options

    if languages.empty? && @submission_latest
      return unless  @ontology.admin?(session[:user])
      content_tag(:div, data: { 'ontology-viewer-tabs-target': 'languageSelector' }, style: "visibility: #{ontology_data_section? ? 'visible' : 'hidden'} ; margin-bottom: -1px;") do
        edit_submission_property_link(@ontology.acronym, @submission_latest.submissionId, :naturalLanguage, container_id: '') do
          ("Enable multilingual display " + content_tag(:i, "", class: "fas fa-lg fa-question-circle")).html_safe
        end
      end
    else
      select_tag name, languages_options, class: '', disabled: !ontology_data_section?, style: "visibility: #{ontology_data_section? ? 'visible' : 'hidden'}; border: none; outline: none;", data: { 'ontology-viewer-tabs-target': 'languageSelector' }
    end
  end

  def language_selector_hidden_tag(section)
    hidden_field_tag "language_selector_hidden_#{section}", '',
                     data: { controller: "language-change", 'language-change-section-value': section, action: "change->language-change#dispatchLangChangeEvent" }
  end

  def languages_options(submission =  @submission || @submission_latest)
    current_lang = request_lang.downcase
    submission_lang = submission_languages(submission)
    # Transform each language into a select option
    submission_lang = submission_lang.map do |lang|
      lang = lang.split('/').last.upcase
      lang = ISO_639.find(lang.to_s.downcase)&.alpha2 || lang
      [lang, lang, { selected: lang.eql?(current_lang) }]
    end

    # Add the option to select all language
    submission_lang.push(['All', 'all', { selected: current_lang.eql?('all') }])

    options_for_select(submission_lang)
  end

  def display_complex_text(definitions)
    html = ""
    definitions.each do |definition|
      if definition.is_a?(String)
        html += '<p class="prefLabel">' + definition + '</p>'
      elsif definition.respond_to?(:uri) && definition.uri
        html += render LinkFieldComponent.new(value: definition.uri)
      else
        html += display_in_multiple_languages(definition)
      end
    end
    return html.html_safe
  end

  def new_view_path(ont_id)
    ont_id_esc = CGI.escape(ont_id)
    if session[:user].nil?
      "/login?redirect=#{escape("/ontologies/new?ontology[viewOf]=#{ont_id_esc}")}"
    else
      "/ontologies/new?ontology[viewOf]=#{ont_id_esc}"
    end
  end

  def new_element_link(title, link)
    if session[:user].nil?
      link = "/login?redirect=#{link}"
    end

    link_to(link, title: title, class: "mx-1") do
      inline_svg_tag("icons/plus.svg", width: '15px', height: '15px')
    end
  end

  def ontology_icon_links(links, submission_latest)
    links.map do |icon, attr, label|
      value = submission_latest.nil? ? nil : submission_latest.send(attr)

      link_options = {
        style: "text-decoration: none; width: 30px; height: 30px"
      }

      if Array(value).empty?
        link_options[:class] = 'disabled-icon'
        link_options[:disabled] = 'disabled'
        title = label
      else
        title = label + '<br>' + link_to(Array(value).first)
      end

      content_tag(:span, data: {controller:"tooltip" } , title:  title) do
        link_to(inline_svg("#{icon}.svg", width: "32", height: '32'),
                Array(value).first || '', link_options)
      end
    end.join.html_safe
  end

  def ontology_depiction_card
    return if Array(@submission_latest&.depiction).empty?

    render Layout::CardComponent.new do
      list_container(@submission_latest.depiction) do |depiction_url|
        render Display::ImageComponent.new(src: depiction_url)
      end
    end
  end

  def metadata_formats_buttons
    render SummarySectionComponent.new(title: 'Download metadata (profile/syntax)', show_card: false) do
      content_tag :div, data: { controller: 'metadata-downloader' } do
        horizontal_list_container([
                                    ['NQuads', 'MOD/n-triple'],
                                    ['JsonLd', 'MOD/json-ld'],
                                    ['XML', 'MOD/rdf-xml']
                                  ]) do |format, label|
          render ChipButtonComponent.new(type: 'clickable', 'data-action': "metadata-downloader#download#{format}") do
            concat content_tag(:span, label)
            concat content_tag(:span, inline_svg("summary/download.svg", width: '15px', height: '15px'))
          end
        end
      end
    end

  end

  def count_subscriptions(ontology_id)
    users = LinkedData::Client::Models::User.all(include: 'subscription', display_context: false, display_links: false)
    users.select { |u| u.subscription.find { |s| s.ontology.eql?(ontology_id) } }.count
  end

  def new_submission_button
    return unless @ontology.admin?(session[:user])
    render RoundedButtonComponent.new(link: new_ontology_submission_path(@ontology.acronym), icon: 'icons/plus.svg',
                                      size: 'medium', title: 'Add new submission')
  end

  def ontology_edit_button
    return unless @ontology.admin?(session[:user])
    render RoundedButtonComponent.new(link: edit_ontology_path(@ontology.acronym), icon: 'edit.svg',
                                      size: 'medium',
                                      title: 'Edit metadata')
  end

  def upload_ontology_button
    if session[:user].nil?
      render Buttons::RegularButtonComponent.new(id: "upload-ontology-button", value: t('home.ontology_upload_button'), variant: "secondary", state: "regular", href: "/login?redirect=/ontologies/new") do |btn|
        btn.icon_left do
          inline_svg_tag "upload.svg"
        end
      end
    else
      render Buttons::RegularButtonComponent.new(id: "upload-ontology-button", value: t('home.ontology_upload_button'), variant: "secondary", state: "regular", href: new_ontology_path) do |btn|
        btn.icon_left do
          inline_svg_tag "upload.svg"
        end
      end
    end
  end

  def submission_json_button
    render RoundedButtonComponent.new(link: "#{(@submission_latest || @ontology).id}?display=all",
                                      target: '_blank',
                                      size: 'medium',
                                      title: 'Go to API')
  end


  def projects_field(projects, ontology_acronym = @ontology.acronym)
    render FieldContainerComponent.new do |f|
      f.label do
        concat "Projects using #{ontology_acronym}"
        concat new_element_link('Create new project', new_project_path)
      end

      if projects.empty?
        empty_state_message("No projects using #{ontology_acronym}")
      else
        horizontal_list_container(projects) do |project|
           render ChipButtonComponent.new(url: project_path(project.acronym), text: project.name, type: "clickable")
        end
      end
    end
  end
  def ontology_import_code(submission = @submission_latest )
    # TODO remove or reuse somewhere elese
    prefix = submission.preferredNamespacePrefix
    namespace= submission.preferredNamespaceUri || submission.URI
    return if prefix.blank? && namespace.blank?

    render ChipButtonComponent.new do
      concat content_tag(:span , "@prefix ", style: 'color: #FA7070')
      concat content_tag(:span , "#{prefix}: ", style: 'color: var(--primary-color);font-weight: 700;')
      concat content_tag(:span , "<#{namespace}>", style: 'color:#9999a9;')
    end
  end
  def metadata_vocabulary_display(vocabularies)
    vocabularies_data = attribute_enforced_values('metadataVoc')
    horizontal_list_container(vocabularies) do |voc|
      label = vocabularies_data[voc] || voc
      label =  content_tag(:span, data: {controller:'tooltip'}, title: "Go to: #{link_to(voc)}") do
        render(ExternalLinkTextComponent.new(text: label))
      end
      render ChipButtonComponent.new(url: voc, text: label, type: 'clickable')
    end
  end

  def summary_only?
    @ontology&.summaryOnly || @submission&.isRemote&.eql?('3')
  end

  def ontology_pull_location?
    !(@submission.pullLocation.nil? || @submission.pullLocation.empty?)
  end

  private

  def submission_languages(submission = @submission)
    Array(submission&.naturalLanguage).map { |natural_language| natural_language["iso639"] && natural_language.split('/').last }.compact
  end
end


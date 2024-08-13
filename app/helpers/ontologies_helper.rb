require 'iso-639'
module OntologiesHelper
  REST_URI = $REST_URL
  API_KEY = $API_KEY
  LANGUAGE_FILTERABLE_SECTIONS = %w[classes schemes collections instances properties].freeze

  def ontology_access_denied?
    @ontology&.errors&.include?('Access denied for this resource')
  end

  def concept_search_input(placeholder)
    content_tag(:div, class: 'search-inputs p-1') do
      text_input(placeholder: placeholder, label: '', name: "search", value: '', data: { action: "input->browse-filters#dispatchInputEvent" })
    end
  end

  def tree_container_component(id:, placeholder:, frame_url:, tree_url:)
    content_tag(:div, class: 'search-page-input-container', data: { controller: "turbo-frame history browse-filters", "turbo-frame-url-value": frame_url, action: "changed->turbo-frame#updateFrame" }) do
      concat(concept_search_input(placeholder))
      concat(content_tag(:div, class: 'tree-container') do
        render(TurboFrameComponent.new(
          id: id,
          src: tree_url,
          data: { 'turbo-frame-target': 'frame' }
        ))
      end)
    end
  end

  def ontology_retired?(submission)
    submission[:status].to_s.eql?('retired') || submission[:deprecated].to_s.eql?('true')
  end
  def ontology_license_badge(acronym, submission = @submission_latest)
    return if submission.nil?

    no_license = submission.hasLicense.blank?
    render ChipButtonComponent.new(class: "text-nowrap chip_button_small #{no_license && 'disabled-link'}", type: no_license ? 'static' : 'clickable') do
      if no_license
        content_tag(:span) do
          content_tag(:span, t('ontologies.no_license'), class: "mx-1") + inline_svg_tag('icons/law.svg', width: "15px")
        end
      else
        link_to_modal(nil, "/ajax/submission/show_licenses/#{acronym}",data: { show_modal_title_value: t('ontologies.access_rights_information')}) do
          content_tag(:span, t('ontologies.view_license'), class: "mx-1") + inline_svg_tag('icons/law.svg')
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
      concat(t('ontologies.referred_to'))
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
    raw(content_tag(:i, '', class: 'fas fa-key', title: t('ontologies.private_ontology'))) if is_private
  end
  def browse_filter_section_label(key)
    labels = {
      categories: t('ontologies.categories'),
      groups: t('ontologies.groups'),
      hasFormalityLevel: t('ontologies.formality_levels'),
      isOfType: t('ontologies.ontology_types'),
      naturalLanguage: t('ontologies.natural_languages')
    }

    labels[key] || key.to_s.underscore.humanize.capitalize
  end

  def browser_counter_loader
    content_tag(:div, class: "browse-desc-text", style: "margin-bottom: 15px;") do
      content_tag(:div, class: "d-flex align-items-center") do
        str = content_tag(:span, t('ontologies.showing'))
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
    html.join("")
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

  def display_contact(contacts)
    contacts.map do |c|
      next unless c.member?(:name) && c.member?(:email)

    html = []

    metadata_not_displayed = ["status", "description", "documentation", "publication", "homepage", "openSearchDescription", "dataDump", "includedInDataCatalog", "logo", "depiction"]

    begin
      metadata_list.each do |metadata, label|
        # Don't display documentation, publication, homepage, status and description, they are already in main details
        if !metadata_not_displayed.include?(metadata)
          # different html build if list or single value

          # METADATA ARRAY
          if sub.send(metadata).kind_of?(Array)
            if sub.send(metadata).any?
              if metadata.eql?("naturalLanguage")
                # Special treatment for naturalLanguage: we want the flags in a bootstrap box
                # UK is gb: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
                lang_codes = []

                sub.send(metadata).each do |lang|
                  if (lang.to_s.eql?("en") || lang.to_s.eql?("eng") || lang.to_s.eql?("http://lexvo.org/id/iso639-3/eng"))
                    # We consider en and eng as english
                    lang_codes << "gb"
                  elsif lang.to_s.start_with?("http://lexvo.org")
                    lang_codes << $LEXVO_TO_FLAG[lang]
                  else
                    lang_codes << lang
                  end
                end

                html << content_tag(:tr) do
                  concat(content_tag(:td, "Natural Language", " "))
                  # Display naturalLanguage as flag
                  concat(content_tag(:td) do
                    concat(content_tag(:ul, { :class => "f32" }) do
                      lang_codes.each do |lang_code|
                        if lang_code.length == 2
                          concat(content_tag(:li, "", { :class => "flag #{lang_code}", :style => "margin-right: 0.5em;" }))
                        else
                          concat(content_tag(:li, lang_code))
                        end
                      end
                    end)
                  end)
                end
              else
                html << content_tag(:tr) do
                  if label.nil?
                    concat(content_tag(:td, metadata.gsub(/(?=[A-Z])/, " ")))
                  else
                    concat(content_tag(:td, label))
                  end

                  metadata_array = []
                  sub.send(metadata).each do |metadata_value|
                    if metadata_value.to_s.start_with?("#{$REST_URL}/ontologies/")
                      # For URI that links to our ontologies we display a button with only the acronym. And redirect to the UI
                      # Warning! Redirection is done by removing "data." from the REST_URL. So might not work perfectly everywhere
                      if metadata_value.to_s.split("/").length < 6
                        # for ontologies/ACRONYM we redirect to the UI url
                        metadata_array.push("<a href=\"#{metadata_value.to_s.sub("data.", "")}\" class=\"btn btn-primary\" target=\"_blank\">#{metadata_value.to_s.split("/")[4..-1].join("/")}</a>")
                      else
                        metadata_array.push("<a href=\"#{metadata_value.to_s}\" class=\"btn btn-primary\" target=\"_blank\">#{metadata_value.to_s.split("/")[4..-1].join("/")}</a>")
                      end
                    elsif metadata_value.to_s =~ /\A#{URI::regexp(["http", "https"])}\z/
                      # Don't create a link if it not an URI
                      metadata_array.push("<a href=\"#{metadata_value.to_s}\" target=\"_blank\">#{metadata_value.to_s}</a>")
                    else
                      metadata_array.push(metadata_value)
                    end
                  end
                  concat(content_tag(:td, raw(metadata_array.join(", "))))
                end
              end
            end
          else

            # SINGLE METADATA
            if !sub.send(metadata).nil?
              html << content_tag(:tr) do
                if label.nil?
                  concat(content_tag(:td, metadata.gsub(/(?=[A-Z])/, " ")))
                else
                  concat(content_tag(:td, label))
                end
                if (metadata.to_s.eql?("hasLicense"))
                  if (sub.send(metadata).to_s.start_with?("http://creativecommons.org/licenses") || sub.send(metadata).start_with?("https://creativecommons.org/licenses"))
                    concat(content_tag(:td) do
                      concat(content_tag(:a, { :rel => "license", :alt => "Creative Commons License",
                                               :href => sub.send(metadata), :target => "_blank", :style => "border-width:0", :title => sub.send(metadata),
                                               :src => "https://i.creativecommons.org/l/by/4.0/88x31.png" }) do
                        concat(content_tag(:img, "", { :rel => "license", :alt => "Creative Commons License", :title => sub.send(metadata),
                                                       :style => "border-width:0", :src => "https://i.creativecommons.org/l/by/4.0/88x31.png" }))
                      end)
                    end)
                  elsif (sub.send(metadata).to_s.start_with?("http://opensource.org/licenses") || sub.send(metadata).start_with?("https://opensource.org/licenses"))
                    concat(content_tag(:td) do
                      concat(content_tag(:a, { :rel => "license", :alt => "Open Source License",
                                               :href => sub.send(metadata), :title => sub.send(metadata), :target => "_blank", :style => "border-width:0;",
                                               :src => "https://opensource.org/files/osi_logo_bold_100X133_90ppi.png" }) do
                        concat(content_tag(:img, "", { :rel => "license", :alt => "Open Source License", :title => sub.send(metadata),
                                                       :style => "height: 80px; border-width:0;", :src => "https://opensource.org/files/osi_logo_bold_100X133_90ppi.png" }))
                      end)
                    end)
                  else
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata), { :rel => "license", :href => sub.send(metadata), :target => "_blank" }))
                    end)
                  end
                elsif (metadata.to_s.eql?("endpoint") && (sub.send(metadata).start_with?("http://sparql.") || sub.send(metadata).start_with?("https://sparql.")))
                  concat(content_tag(:td) do
                    concat(content_tag(:a, { :href => sub.send(metadata), :title => sub.send(metadata),
                                             :target => "_blank", :style => "border-width:0;" }) do
                      concat(image_tag("logos/sparql_logo.png", title: sub.send(metadata), class: "logo"))
                    end)
                  end)
                elsif sub.send(metadata).to_s.start_with?("#{$REST_URL}/ontologies/")
                  # For URI that links to our ontologies we display a button with only the acronym. And redirect to the UI
                  # Warning! Redirection is done by removing "data." from the REST_URL. So might not work perfectly everywhere
                  if sub.send(metadata).to_s.split("/").length < 6
                    # for ontologies/ACRONYM we redirect to the UI url
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata).to_s.split("/")[4..-1].join("/"), { :class => "btn btn-primary",
                                                                                                    :href => sub.send(metadata).sub("data.", ""), :target => "_blank", :title => sub.send(metadata) }))
                    end)
                  else
                    concat(content_tag(:td) do
                      concat(content_tag(:a, sub.send(metadata).to_s.split("/")[4..-1].join("/"), { :class => "btn btn-primary",
                                                                                                    :href => sub.send(metadata), :target => "_blank", :title => sub.send(metadata) }))
                    end)
                  end
                else
                  if sub.send(metadata).to_s =~ /\A#{URI::regexp(["http", "https"])}\z/
                    # Don't create a link if it not an URI
                    concat(content_tag(:td, raw("<a href=\"#{sub.send(metadata).to_s}\" target=\"_blank\">#{sub.send(metadata).to_s}</a>")))
                  else
                    concat(content_tag(:td, raw(sub.send(metadata).to_s)))
                  end
                end
              end
            end
          end
        end
      end
    rescue => e
      LOG.add :debug, "Unable to retrieve additional ontology metadata"
      LOG.add :debug, "error: #{e}"
      LOG.add :debug, "error message: #{e.message}"
    end
    html.join("")
  end

  def count_links(ont_acronym, page_name = "summary", count = 0)
    ont_url = "/ontologies/#{ont_acronym}"
    if count.nil? || count.zero?
      return "0"
    else
      return "<a href='#{ont_url}/?p=#{page_name}'>#{number_with_delimiter(count, delimiter: ",")}</a>"
    end
  end

  def classes_link(ontology, count)
    return "0" if ontology.summaryOnly || count.nil? || count.zero?

    count_links(ontology.ontology.acronym, "classes", count)
  end

  def metadata_filled_count(submission = @submission_latest, ontology = @ontology)
    return if submission.nil?

    reject = [:csvDump, :dataDump, :openSearchDescription, :metrics, :prefLabelProperty, :definitionProperty,
              :definitionProperty, :synonymProperty, :authorProperty, :hierarchyProperty, :obsoleteProperty,
              :ontology, :endpoint, :submissionId, :submissionStatus, :uploadFilePath, :context, :links, :ontology]
    sub_values = submission.to_hash.except(*reject).values
    count = sub_values.count{|x| !x.blank?}
    content_tag(:div, class: 'd-flex align-items-center justify-content-center') do
      content_tag(:span, style:'width: 50px; height: 50px', data: {controller: 'tooltip'}, title: "#{count} of #{sub_values.size}") do
        render CircleProgressBarComponent.new(count: count , max:  sub_values.size )
      end  +  content_tag(:span, class: 'mx-1') { t('ontologies.metadata_properties', acronym: ontology.acronym)}
    end.html_safe
  end

  # Creates a link based on the status of an ontology submission
  def download_link(submission, ontology = nil)
    ontology ||= @ontology
    links = []
    if ontology.summaryOnly
      if submission.homepage.nil?
        link = "N/A - metadata only"
      else
        uri = submission.homepage
        links << { href: uri, label: t('ontologies.home_page') }
      end
    else
      uri = submission.id + "/download?apikey=#{get_apikey}"
      link = "<a href='#{uri}' 'rel='nofollow'>#{submission.pretty_format}</a>"
      latest = ontology.explore.latest_submission({ include_status: "ready" })
      if latest && latest.submissionId == submission.submissionId
        link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=csv' rel='nofollow'>CSV</a>"
        if !latest.hasOntologyLanguage.eql?("UMLS")
          link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=rdf' rel='nofollow'>RDF/XML</a>"
        end
      end
      unless submission.diffFilePath.nil?
        uri = submission.id + "/download_diff?apikey=#{get_apikey}"
        links << { href: uri, label: "DIFF" }
      end
    end
    links
  end



  def mappings_link(ontology, count)
    return "0" if ontology.summaryOnly || count.nil? || count.zero?

    count_links(ontology.ontology.acronym, "mappings", count)
  end

  def notes_link(ontology, count)
    count_links(ontology.ontology.acronym, "notes", count)
  end

  # Creates a link based on the status of an ontology submission
  def status_link(submission, latest = false, target = "")
    version_text = submission.version.nil? || submission.version.to_s.length == 0 ? "unknown" : submission.version.to_s
    status_text = " <span class='ontology_submission_status'>" + submission_status2string(submission) + "</span>"
    if submission.ontology.summaryOnly || latest == false
      version_link = version_text
    else
      version_link = "<a href='/ontologies/#{submission.ontology.acronym}?p=classes' #{target.empty? ? "" : "target='#{target}'"}>#{version_text}</a>"
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
    codes = sub.submissionStatus.map { |s| s.split("/").last }
    errors = codes.select { |c| c.start_with? "ERROR" }.map { |c| c.gsub("_", " ").split(/(\W)/).map(&:capitalize).join }.compact
    status = []
    status.push("Parsed") if (codes.include? "RDF") && (codes.include? "RDF_LABELS")
    # The order of this array imposes an oder on the UI status code string
    status_list = ["INDEXED", "METRICS", "ANNOTATOR", "ARCHIVED"]
    status_list.insert(0, "UPLOADED") unless status.include?("Parsed")
    status_list.each do |c|
      status.push(c.capitalize) if codes.include? c
    end
    status.concat errors
    return "" if status.empty?

    "(" + status.join(", ") + ")"
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
      status_icons(ok: true)
    elsif submission_status_error?(status)
      status_icons(error: true)
    elsif status == '(Archived)'
      'archive.svg'
    elsif submission_status_warning?(status)
      status_icons(warning: true)
    else
      "info.svg"
    end
  end

  def status_icons(ok: false, error: false, warning: false)
    if ok
      "success-icon.svg"
    elsif error
      'error-icon.svg'
    elsif warning
      "alert-triangle.svg"
    else
      "info.svg"
    end
  end

  # Link for private/public/licensed ontologies
  def visibility_link(ontology)
    ont_url = "/ontologies/#{ontology.acronym}" # 'ontology' is NOT a submission here
    page_name = "summary"  # default ontology page view for visibility link
    link_name = "Public"   # default ontology visibility
    if ontology.summaryOnly
      link_name = "Summary Only"
    elsif ontology.private?
      link_name = "Private"
    elsif ontology.licensed?
      link_name = "Licensed"
    end
    "<a href='#{ont_url}/?p=#{page_name}'>#{link_name}</a>"
  end

  def category_name_chip_component(domain)
    text = domain.split('/').last.titleize


    return render(ChipButtonComponent.new(text: text, tooltip: domain,  type: "static")) unless link?(domain)


    acronym = domain.split('/').last.upcase.strip
    category = LinkedData::Client::Models::Category.find(acronym)

    if category.name
      render ChipButtonComponent.new(text: text, tooltip: category.name,  type: "static")
    else
      render ChipButtonComponent.new(text: text, tooltip: domain,  url: domain, type: "clickable", target: '_blank')
    end

  end


  def show_ontology_domains(domains)
    if domains.length == 1 && domains[0].include?(',')
      domains[0].split(',').map(&:strip)
    else
      domains
    end
  end

  def show_group_name(domain)
    return domain unless link?(domain)

    acronym = domain.split('/').last.upcase.strip
    category = LinkedData::Client::Models::Group.find(acronym)
    category ? category.name : acronym.titleize
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
    (params[:p]) ? params[:p] : "summary"
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
                                     loading: Rails.env.development? ? "lazy" : "eager",
                                     target: '_top', data: { "turbo-frame-target": "frame" })
    end
  end

  def visits_chart_dataset(visits_data)
    [{
      label: "Visits",
      data: visits_data,
      backgroundColor: "rgba(151, 187, 205, 0.2)",
      borderColor: "rgba(151, 187, 205, 1)",
      pointBorderColor: "rgba(151, 187, 205, 1)",
      pointBackgroundColor: "rgba(151, 187, 205, 1)",
    }].to_json
  end

  def sections_to_show
    sections = ["summary"]

    unless @ontology.summaryOnly || @submission_latest.nil?
      sections += %w[classes properties notes mappings]
      sections += %w[schemes collections] if skos?
      sections += %w[instances] unless skos?
      sections += %w[notes mappings widgets sparql]
    end
    sections
  end
end

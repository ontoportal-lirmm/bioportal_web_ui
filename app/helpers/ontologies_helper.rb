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

  def agent?(sub_metadata, attr)
    metadata = sub_metadata.select{ |x| x['@id'][attr] }.first
    metadata && Array(metadata['enforce']).include?('Agent')
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

  # Add additional metadata as html for a submission
  def additional_metadata(sub)
    # Get the list of metadata attribute from the REST API
    json_metadata = submission_metadata
    metadata_list = {}
    # Get extracted metadata and put them in a hash with their label, if one, as value
    json_metadata.each do |metadata|
      metadata_list[metadata["attribute"]] = metadata["label"]
    end
    metadata_list = metadata_list.sort

    html = []

    metadata_not_displayed = ["status", "description", "documentation", "publication", "homepage",
                              "openSearchDescription", "dataDump", "includedInDataCatalog", "logo",
                              "depiction", "submissionId", "submissionStatus", 'ontology', 'contact']
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

              elsif agent?(json_metadata, metadata)
                html << content_tag(:tr) do
                  if label.nil?
                    concat(content_tag(:td, metadata.gsub(/(?=[A-Z])/, " ")))
                  else
                    concat(content_tag(:td, label))
                  end

                  metadata_array = []

                  sub.send(metadata).each do |metadata_value|
                    metadata_array << "<div> #{display_agent(metadata_value)} </div>"
                  end

                  concat(content_tag(:td, raw(metadata_array.join(""))))
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

                    elsif metadata_value.to_s =~ /\A#{URI::regexp(['http', 'https'])}\z/
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
            if agent?(json_metadata, metadata)
              next if sub.send(metadata).nil?

              html << content_tag(:tr) do
                if label.nil?
                  concat(content_tag(:td, metadata.gsub(/(?=[A-Z])/, " ")))
                else
                  concat(content_tag(:td, label))
                end
                concat(content_tag(:td, raw("<div> #{display_agent(sub.send(metadata))} </div>")))
              end
            elsif !sub.send(metadata).nil?
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

                      concat(image_tag('logos/sparql_logo.png', title: sub.send(metadata), class: 'logo'))
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
                  if sub.send(metadata).to_s =~ /\A#{URI::regexp(['http', 'https'])}\z/
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
    if ontology.summaryOnly
      if submission.homepage.nil?
        link = 'N/A - metadata only'
      else
        uri = submission.homepage
        link = "<a href='#{uri}'>Home Page</a>"
      end
    else
      uri = submission.id + "/download?apikey=#{get_apikey}"
      link = "<a href='#{uri}' 'rel='nofollow'>#{submission.pretty_format}</a>"
      latest = ontology.explore.latest_submission({ include_status: 'ready' })
      if latest && latest.submissionId == submission.submissionId
        link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=csv' rel='nofollow'>CSV</a>"
        if !latest.hasOntologyLanguage.eql?('UMLS')
          link += " | <a href='#{ontology.id}/download?apikey=#{get_apikey}&download_format=rdf' rel='nofollow'>RDF/XML</a>"
        end
      end
      unless submission.diffFilePath.nil?
        uri = submission.id + "/download_diff?apikey=#{get_apikey}"
        link = link + " | <a href='#{uri} 'rel='nofollow'>DIFF</a>"
      end
    end
    link
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
            id: "ont-#{section_title}-tab", class: "nav-link #{selected_section?(section_title) ? 'active show' : ''}",
            data: { action: 'click->ontology-viewer-tabs#selectTab',
                    toggle: "tab", target: "#ont_#{section_title}_content", 'bp-ont-page': section_title ,
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
      select_tag name, languages_options, class: '', disabled: !ontology_data_section?, style: "visibility: #{ontology_data_section? ? 'visible' : 'hidden'}; border: none; outline: none;", data: {'ontology-viewer-tabs-target': 'languageSelector'}
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
        html += '<p class="prefLabel">' + definition + '</p>'
      elsif definition.respond_to?(:uri) && definition.uri
        html += render LinkFieldComponent.new(value: definition.uri)
      end
    end
    return html.html_safe
  end


  def count_subscriptions(ontology_id)
    users = LinkedData::Client::Models::User.all(include: 'subscription', display_context: false, display_links: false )
    users.select{ |u| u.subscription.find{ |s| s.ontology.eql?(ontology_id)} }.count
  end

  def ontology_edit_button
    return unless  @ontology.admin?(session[:user])
    render RoundedButtonComponent.new(link:   edit_ontology_path(@ontology.acronym), icon: 'edit.svg', size: 'medium')
  end

  def submission_json_button
    render RoundedButtonComponent.new(link:  "#{(@submission_latest || @ontology).id}?display=all", target: '_blank', size: 'medium')
  end

  def attribute_error(attr)
    return '' unless @errors && @errors[attr.to_sym]
    errors = @errors[attr.to_sym]

    errors.values.join(', ')
  end

  def error_message
    if !@errors[:error].nil? && @errors[:error].is_a?(String)
      @errors[:error]
    else
      "Errors in fields #{@errors.keys.join(', ')}"
    end

  end
  private

  def submission_languages(submission = @submission)
    submission&.naturalLanguage.map { |natural_language| natural_language["iso639"] && natural_language.split('/').last }.compact
  end
end


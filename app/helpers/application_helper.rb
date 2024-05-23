# Methods added to this helper will be available to all templates in the application.

require 'uri'
require 'cgi'
require 'digest/sha1'
require 'pry' # used in a rescue

module ApplicationHelper
  REST_URI = $REST_URL
  API_KEY = $API_KEY

  include ModalHelper, MultiLanguagesHelper, UrlsHelper

  RESOLVE_NAMESPACE = {:omv => "http://omv.ontoware.org/2005/05/ontology#", :skos => "http://www.w3.org/2004/02/skos/core#", :owl => "http://www.w3.org/2002/07/owl#",
                       :rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", :rdfs => "http://www.w3.org/2000/01/rdf-schema#", :metadata => "http://data.bioontology.org/metadata/",
                       :metadata_def => "http://data.bioontology.org/metadata/def/", :dc => "http://purl.org/dc/elements/1.1/", :xsd => "http://www.w3.org/2001/XMLSchema#",
                       :oboinowl_gen => "http://www.geneontology.org/formats/oboInOwl#", :obo_purl => "http://purl.obolibrary.org/obo/",
                        :umls => "http://bioportal.bioontology.org/ontologies/umls/", :door => "http://kannel.open.ac.uk/ontology#", :dct => "http://purl.org/dc/terms/",
                        :void => "http://rdfs.org/ns/void#", :foaf => "http://xmlns.com/foaf/0.1/", :vann => "http://purl.org/vocab/vann/", :adms => "http://www.w3.org/ns/adms#",
                        :voaf => "http://purl.org/vocommons/voaf#", :dcat => "http://www.w3.org/ns/dcat#", :mod => "http://www.isibang.ac.in/ns/mod#", :prov => "http://www.w3.org/ns/prov#",
                       :cc => "http://creativecommons.org/ns#", :schema => "http://schema.org/", :doap => "http://usefulinc.com/ns/doap#", :bibo => "http://purl.org/ontology/bibo/",
                       :wdrs => "http://www.w3.org/2007/05/powder-s#", :cito => "http://purl.org/spar/cito/", :pav => "http://purl.org/pav/", :nkos => "http://w3id.org/nkos/nkostype#",
                       :oboInOwl => "http://www.geneontology.org/formats/oboInOwl#", :idot => "http://identifiers.org/idot/", :sd => "http://www.w3.org/ns/sparql-service-description#",
                       :cclicense => "http://creativecommons.org/licenses/",
                       'skos-xl' => "http://www.w3.org/2008/05/skos-xl#"}
  def url_to_endpoint(url)
    uri = URI.parse(url)
    endpoint = uri.path.sub(/^\//, '')
    endpoint
  end

  def search_json_link(link = @json_url, style: '')
    custom_style = "font-size: 50px; line-height: 0.5; margin-left: 6px; #{style}".strip
    render IconWithTooltipComponent.new(icon: "json.svg",link: link, target: '_blank', title: t('fair_score.go_to_api'), size:'small', style: custom_style)
  end

  def resolve_namespaces
    RESOLVE_NAMESPACE
  end
  def ontologies_analytics
    data = LinkedData::Client::Analytics.last_month.onts
    data.map{|x| [x[:ont].to_s, x[:views]]}.to_h
  end

  def get_apikey
    unless session[:user].nil?
      return session[:user].apikey
    else
      return LinkedData::Client.settings.apikey
    end
  end

  def rest_hostname
    extract_hostname(REST_URI)
  end

  def extract_hostname(url)
    begin
      uri = URI.parse(url)
      uri.hostname
    rescue URI::InvalidURIError
      url
    end
  end

  def omniauth_providers_info
    $OMNIAUTH_PROVIDERS
  end

  def omniauth_provider_info(strategy)
    omniauth_providers_info.select {|k,v| v[:strategy].eql?(strategy.to_sym) || k.eql?(strategy)}
  end

  def omniauth_token_provider(strategy)
    omniauth_provider_info(strategy.to_sym).keys.first
  end

  def isOwner?(id)
    unless session[:user].nil?
      if session[:user].admin?
        return true
      elsif session[:user].id.eql?(id)
        return true
      else
        return false
      end
    end
  end



  def encode_param(string)
    CGI.escape(string)
  end

  def clean(string)
    string = string.gsub("\"",'\'')
    return string.gsub("\n",'')
  end

  def clean_id(string)
    new_string = string.gsub(":","").gsub("-","_").gsub(".","_")
    return new_string
  end

  def to_param(string)
     "#{encode_param(string.gsub(" ","_"))}"
  end

  def get_username(user_id)
    user = LinkedData::Client::Models::User.find(user_id)
    username = user.nil? ? user_id : user.username
    username
  end

  def current_user
    session[:user]
  end

  def current_user_admin?
    session[:user] && session[:user].admin?
  end


  def child_id(child)
    child.id.to_s.split('/').last
  end

  def loading_spinner(padding = false, include_text = true)
    loading_text = include_text ? t('application.loading') : ""
    if padding
      raw('<div style="padding: 1em;">' + image_tag("spinners/spinner_000000_16px.gif", style: "vertical-align: text-bottom;") + loading_text + '</div>')
    else
      raw(image_tag("spinners/spinner_000000_16px.gif", style: "vertical-align: text-bottom;") + loading_text)
    end
  end



  def help_icon(link, html_attribs = {})
    html_attribs["title"] ||= "Help"
    attribs = []
    html_attribs.each {|k,v| attribs << "#{k.to_s}='#{v}'"}
    return <<-BLOCK
          <a target="_blank" href='#{link}' class='pop_window help_link' #{attribs.join(" ")}>
            <span class="pop_window ui-icon ui-icon-help"></span>
          </a>
    BLOCK
  end

  # Create a popup button with a ? inside to display help when hovered
  def help_tooltip(content, html_attribs = {}, icon = 'fas fa-question-circle', css_class = nil, text = nil)
    html_attribs["title"] = content
    attribs = []
    html_attribs.each {|k,v| attribs << "#{k.to_s}='#{v}'"}
    return <<-BLOCK
          <a data-controller='tooltip' class='pop_window tooltip_link d-inline-block #{[css_class].flatten.compact.join(' ')}' #{attribs.join(" ")}>
            <i class="#{icon} d-flex"></i> #{text}
          </a>
    BLOCK
  end

  def error_message_text
    return @errors if @errors.is_a?(String)
    @errors = @errors[:error] if @errors && @errors[:error]
    t('application.errors_in_fields', errors: @errors.keys.join(', '))
  end

  def error_message_alert
    return if @errors.nil?

    content_tag(:div, class: 'my-1') do
      render Display::AlertComponent.new(message: error_message_text, type: 'danger', closable: false)
    end
  end

  def onts_for_select
    ontologies ||= LinkedData::Client::Models::Ontology.all(include: "acronym,name")
    onts_for_select = [['', '']]
    ontologies.each do |ont|
      next if ( ont.acronym.nil? or ont.acronym.empty? )
      acronym = ont.acronym
      name = ont.name
      abbreviation = acronym.empty? ? "" : "(#{acronym})"
      ont_label = "#{name.strip} #{abbreviation}"
      onts_for_select << [ont_label, acronym]
    end
    onts_for_select.sort! { |a,b| a[0].downcase <=> b[0].downcase }
    onts_for_select
  end

  def link_last_part(url)
    return "" if url.nil?

    if url.include?('#')
      url.split('#').last
    else
      url.split('/').last
    end
  end

  def get_categories_data(categories = nil)
    @categories_for_select = []
    @categories_map = {}
    categories ||= LinkedData::Client::Models::Category.all(include: "name,ontologies")
    categories.each do |c|
      @categories_for_select << [ c.name, c.id ]
      @categories_map[c.id] = ontologies_to_acronyms(c.ontologies) # c.ontologies is a list of URIs
    end
    @categories_for_select.sort! { |a,b| a[0].downcase <=> b[0].downcase }
    @categories_for_js = @categories_map.to_json
  end

  def get_groups_data(groups = nil)
    @groups_map = {}
    @groups_for_select = []
    groups ||= LinkedData::Client::Models::Group.all(include: "acronym,name,ontologies")
    groups.each do |g|
      next if ( g.acronym.nil? or g.acronym.empty? )
      @groups_for_select << [ g.name + " (#{g.acronym})", g.acronym ]
      @groups_map[g.acronym] = ontologies_to_acronyms(g.ontologies) # g.ontologies is a list of URIs
    end
    @groups_for_select.sort! { |a,b| a[0].downcase <=> b[0].downcase }
    @groups_for_js = @groups_map.to_json
  end




  def ontologies_to_acronyms(ontologyIDs)
    acronyms = []
    ontologyIDs.each do |id|
      acronyms << @onts_uri2acronym_map[id]  # hash generated in get_ontologies_data
    end
    return acronyms.compact # remove nil values from any failures to convert ontology URI to acronym
  end

  def at_slice?
    !@subdomain_filter.nil? && !@subdomain_filter[:active].nil? && @subdomain_filter[:active] == true
  end


  # TODO this helper is not used but can be usefully
  def truncate_with_more(text, options = {})
    length ||= options[:length] ||= 30
    trailing_text ||= options[:trailing_text] ||= " ... "
    link_more ||= options[:link_more] ||= "[more]"
    link_less ||= options[:link_less] ||= "[less]"
    more_text = " <a href='javascript:void(0);' class='truncated_more'>#{link_more}</a></span><span class='truncated_less'>#{text} <a href='javascript:void(0);' class='truncated_less'>#{link_less}</a></span>"
    more = text.length > length ? more_text : "</span>"
    output = "<span class='more_less_container'><span class='truncated_more'>#{truncate(text, :length => length, :omission => trailing_text)}" + more + "</span>"
  end

  def chips_component(id: , name: , label: , value: , checked: false , tooltip: nil, &block)
    content_tag(:div, data: { controller: 'tooltip' }, title: tooltip) do
      check_input(id: id, name: name, value: value, label: label, checked: checked, &block)
    end
  end

  def group_chip_component(id: nil, name: , object: , checked: , value: nil, title: nil, &block)
    title ||= object["name"]
    value ||= (object["value"] || object["acronym"] || object["id"])

    chips_component(id: id || value, name: name, label: object["acronym"],
                    checked: checked,
                    value: value, tooltip: title, &block)
  end
  alias  :category_chip_component :group_chip_component

  def add_comment_button(parent_id, parent_type)
    if session[:user].nil?
      link_to t('application.add_comment'),  login_index_path(redirect: request.url), class: "secondary-button regular-button slim"
    else
      link_to_modal t('application.add_comment'), notes_new_comment_path(parent_id: parent_id, parent_type: parent_type, ontology_id: @ontology.acronym),
                    class: "secondary-button regular-button slim", data: { show_modal_title_value: t('application.add_new_comment')}
    end
  end

  def add_reply_button(parent_id)
    if session[:user].nil?
      link_to t('application.reply'), login_index_path, 'data-turbo': false
    else
      link_to t('application.reply'), notes_new_reply_path(parent_id: parent_id ), "data-turbo-frame": "#{parent_id}_new_reply"
    end
  end


  def add_proposal_button(parent_id, parent_type)
    if session[:user].nil?
      link_to t('application.add_proposal'),  login_index_path(redirect: request.url), class: "secondary-button regular-button slim"
    else
      link_to_modal t('application.add_proposal'), notes_new_proposal_path(parent_id: parent_id, parent_type: parent_type, ontology_id: @ontology.acronym),
                    class: "secondary-button regular-button slim", data: { show_modal_title_value: t('application.add_new_proposal')}
    end
  end
  

  def link?(str)
    # Regular expression to match strings starting with "http://" or "https://"
    link_pattern = /\Ahttps?:\/\//
    str = str&.strip
    # Check if the string matches the pattern
    !!(str =~ link_pattern)
  end

  def subscribe_button(ontology_id)
    return if ontology_id.nil?
    render TurboFrameComponent.new(id: 'subscribe_button', src: ontology_subscriptions_path(ontology_id: ontology_id.split('/').last), class: 'ml-1') do |t|
      t.loader do
        content_tag(:div, style: 'margin-left: 10px;') do
          render PillButtonComponent.new do
            (content_tag(:span, t('application.watching'), class: 'ml-1') + render(LoaderComponent.new(small: true))).html_safe
          end
        end
      end
    end
  end

  def admin_block(ontology: @ontology, user: session[:user], class_css: "admin-border", &block)
    if ontology.admin?(user)
      content_tag(:div, class: class_css) do
        capture(&block) if block_given?
      end
    end
  end


  def subscribed_to_ontology?(ontology_acronym, user)
    user.bring(:subscription) if user.subscription.nil?
    # user.subscription is an array of subscriptions like {ontology: ontology_id, notification_type: "NOTES"}
    return false if user.subscription.nil? or user.subscription.empty?
    user.subscription.each do |sub|
      #sub = {ontology: ontology_acronym, notification_type: "NOTES"}
      sub_ont_acronym = sub[:ontology] ?  sub[:ontology].split('/').last : nil #  make sure we get the acronym, even if it's a full URI
      return true if sub_ont_acronym == ontology_acronym
    end
    return false
  end

  def ontolobridge_instructions_template(ontology)
    ont_data = Ontology.find_by(acronym: ontology.acronym)
    ont_data.nil? || ont_data.new_term_instructions.empty? ? t('concepts.request_term.new_term_instructions') : ont_data.new_term_instructions
  end

  # http://stackoverflow.com/questions/1293573/rails-smart-text-truncation
  def smart_truncate(s, opts = {})
    opts = {:words => 20}.merge(opts)
    if opts[:sentences]
      return s.split(/\.(\s|$)+/)[0, opts[:sentences]].map{|s| s.strip}.join('. ') + '. ...'
    end
    a = s.split(/\s/) # or /[ ]+/ to only split on spaces
    n = opts[:words]
    a[0...n].join(' ') + (a.size > n ? '...' : '')
  end

  # convert xml_date_time_str from triple store into "mm/dd/yyyy", e.g.:
  # parse_xmldatetime_to_date( '2010-06-27T20:17:41-07:00' )
  # => '06/27/2010'
  def xmldatetime_to_date(xml_date_time_str)
    require 'date'
    d = DateTime.xmlschema( xml_date_time_str ).to_date
    # Return conventional US date format:
    return sprintf("%02d/%02d/%4d", d.month, d.day, d.year)
    # Or return "yyyy/mm/dd" format with:
    #return DateTime.xmlschema( xml_date_time_str ).to_date.to_s
  end

  def notification_type(flash_key)
    bootstrap_alert_class = {
      'notice' => 'success',
      'success' => 'success',
      'error' => 'error',
      'alert' => 'alert'
    }
    bootstrap_alert_class[flash_key]
  end

  ###BEGIN ruby equivalent of JS code in bp_ajax_controller.
  ###Note: this code is used in concepts/_details partial.
  def bp_ont_link(ont_acronym)
    return "/ontologies/#{ont_acronym}"
  end

  def bp_class_link(cls_id, ont_acronym)
    return "#{bp_ont_link(ont_acronym)}?p=classes&conceptid=#{escape(cls_id)}&language=#{request_lang}"
  end

  def bp_scheme_link(scheme_id, ont_acronym)
    return "#{bp_ont_link(ont_acronym)}?p=schemes&schemeid=#{escape(scheme_id)}"
  end

  def bp_label_xl_link(label_xl_id, ont_acronym)
    return "#{bp_ont_link(ont_acronym)}/?label_xl_id=#{escape(label_xl_id)}"
  end

  def bp_collection_link(collection_id, ont_acronym)
    "#{bp_ont_link(ont_acronym)}?p=collection&collectionid=#{escape(collection_id)}"
  end

  def label_ajax_data_h(cls_id, ont_acronym, ajax_uri, cls_url)
    { data:
        {
          'label-ajax-cls-id-value': cls_id,
          'label-ajax-ontology-acronym-value': ont_acronym,
          'label-ajax-ajax-url-value': ajax_uri,
          'label-ajax-cls-id-url-value': cls_url
        }
    }
  end

  def label_ajax_data(cls_id, ont_acronym, ajax_uri, cls_url)
    label_ajax_data_h(cls_id, ont_acronym, ajax_uri, cls_url)
  end

  def label_ajax_link(link, cls_id, ont_acronym, ajax_uri, cls_url, target = nil)
    data = label_ajax_data(cls_id, ont_acronym, ajax_uri, cls_url)
    options = {  'data-controller': 'label-ajax' }.merge(data)
    options = options.merge({ target: target }) if target
    content_tag(:span, class: 'mx-1') do
      render ChipButtonComponent.new(url: link, text: cls_id, type: 'clickable', **options)
    end
  end

  def get_link_for_cls_ajax(cls_id, ont_acronym, target = nil)
    if cls_id.start_with?('http://') || cls_id.start_with?('https://')
      link = bp_class_link(cls_id, ont_acronym)
      ajax_url = '/ajax/classes/label'
      cls_url = "/ontologies/#{ont_acronym}?p=classes&conceptid=#{CGI.escape(cls_id)}"
      label_ajax_link(link, cls_id, ont_acronym, ajax_url , cls_url ,target)
    else
      content_tag(:div, auto_link(cls_id, :all, target: '_blank'))
    end
  end

  def get_link_for_ont_ajax(ont_acronym)
    # ajax call will replace the acronym with an ontology name (triggered by class='ont4ajax')
    href_ont = " href='#{bp_ont_link(ont_acronym)}' "
    data_ont = " data-ont='#{ont_acronym}' "
    return "<a class='ont4ajax' #{data_ont} #{href_ont}>#{ont_acronym}</a>"
  end

  def get_link_for_scheme_ajax(scheme, ont_acronym, target = '_blank')
    link = bp_scheme_link(scheme, ont_acronym)
    ajax_url = "/ajax/schemes/label?language=#{request_lang}"
    scheme_url = "?p=schemes&schemeid=#{CGI.escape(scheme)}"
    label_ajax_link(link, scheme, ont_acronym, ajax_url, scheme_url, target)
  end

  def get_link_for_collection_ajax(collection, ont_acronym, target = '_blank')
    link = bp_collection_link(collection, ont_acronym)
    ajax_url = "/ajax/collections/label?language=#{request_lang}"
    collection_url = "?p=collections&collectionid=#{CGI.escape(collection)}"
    label_ajax_link(link, collection, ont_acronym, ajax_url, collection_url, target)
  end


  def get_link_for_label_xl_ajax(label_xl, ont_acronym, cls_id, modal: true)
    link = label_xl
    ajax_uri = "/ajax/label_xl/label?cls_id=#{CGI.escape(cls_id)}"
    label_xl_url = "/ajax/label_xl/?id=#{CGI.escape(label_xl)}&ontology=#{ont_acronym}&cls_id=#{CGI.escape(cls_id)}"
    data = label_ajax_data_h(label_xl, ont_acronym, ajax_uri, label_xl_url)
    data[:data][:controller] = 'label-ajax'
    if modal
      link_to_modal(cls_id, link, {data: data[:data] , class: 'btn btn-sm btn-light m-1'})
    else
      link_to(link,'', {data: data[:data], class: 'btn btn-sm btn-light m-1', target: '_blank'})
    end


  end

  ###END ruby equivalent of JS code in bp_ajax_controller.
  def ontology_viewer_page_name(ontology_name, concept_label, page)
    ontology_name + " | "  + " #{page.capitalize}"
  end
  def help_path(anchor: nil)
    "#{Rails.configuration.settings.links[:help]}##{anchor}"
  end

  def uri?(url)
    url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
  end

  def extract_label_from(uri)
    label = uri.to_s.chomp('/').chomp('#')
    index = label.index('#')
    if !index.nil?
      label = label[(index + 1) , uri.length-1]
    else
      index = label.rindex('/')
      label = label[(index + 1), uri.length-1]  if index > -1 && index < (uri.length - 1)
    end
    label
  end

  def skos?
    submission = @submission || @submission_latest
    submission&.hasOntologyLanguage === 'SKOS'
  end

  def current_page?(path)
    request.path.eql?(path)
  end

  def bp_config_json
    # For config settings, see
    # config/bioportal_config.rb
    # config/initializers/ontologies_api_client.rb
    config = {
      org: $ORG,
      org_url: $ORG_URL,
      site: $SITE,
      org_site: $ORG_SITE,
      ui_url: $UI_URL,
      apikey: LinkedData::Client.settings.apikey,
      userapikey: get_apikey,
      rest_url: LinkedData::Client.settings.rest_url,
      proxy_url: $PROXY_URL,
      biomixer_url: $BIOMIXER_URL,
      annotator_url: $ANNOTATOR_URL,
      ncbo_annotator_url: $NCBO_ANNOTATOR_URL,
      ncbo_apikey: $NCBO_API_KEY,
      interportal_hash: $INTERPORTAL_HASH,
      resolve_namespace: RESOLVE_NAMESPACE
    }
    config[:ncbo_slice] = @subdomain_filter[:acronym] if (@subdomain_filter[:active] && !@subdomain_filter[:acronym].empty?)
    config.to_json
  end

  def portal_name
    $SITE
  end

  def navitems
    items = [["/ontologies", t('layout.header.browse')],
             ["/mappings", t('layout.header.mappings')],
             ["/recommender", t("layout.header.recommender")],
             ["/annotator", t("layout.header.annotator")],
             ["/landscape", t("layout.header.landscape")]]
  end


  def beta_badge(text = t('application.beta_badge_text'), tooltip: t('application.beta_badge_tooltip'))
    return unless text
    content_tag(:span, text, data: { controller: 'tooltip' }, title: tooltip, class: 'badge badge-pill bg-secondary text-white')
  end

  def attribute_enforced_values(attr)
    submission_metadata.select {|x| x['@id'][attr]}.first['enforcedValues']
  end

  def prefix_properties(concept_properties)
    modified_properties = {}

    concept_properties&.each do |key, value|
      if value.is_a?(Hash) && value.key?(:key)
        key_string = value[:key].to_s
        next if key_string.include?('metadata')

        modified_key = prefix_property_url(key_string, key)

        if modified_key
          modified_properties[modified_key] = value
        else
          modified_properties[link_last_part(key_string)] = value
        end

      end
    end

    modified_properties
  end

  def rest_url
    # Split the URL into protocol and path parts
    protocol, path = $REST_URL.split("://", 2)

    # Remove the last '/' in the path part
    cleaned_path = path.chomp('/')
    # Reconstruct the cleaned URL
    "#{protocol}://#{cleaned_path}"
  end


  def prefix_property_url(key_string, key = nil)
    namespace_key, _ = RESOLVE_NAMESPACE.find { |_, value| key_string.include?(value) }

    if key && namespace_key
      "#{namespace_key}:#{key}"
    elsif key.nil? && namespace_key
      namespace_key
    else # we don't try to guess the prefix
      nil
    end
  end

  def prefixed_url(url)
    key = link_last_part(url)
    prefix_property_url(url.split(key).first, key)
  end

  def show_advanced_options_button(text: nil, init: nil)
    content_tag(:div, class: "#{init ? 'd-none' : ''} advanced-options-button", 'data-action': 'click->reveal-component#show', 'data-reveal-component-target': 'showButton') do
      inline_svg_tag('icons/settings.svg') +
      content_tag(:div, text, class: 'text')
    end
  end

  def hide_advanced_options_button(text: nil, init: nil)
    content_tag(:div, class: "#{init ? '' : 'd-none'} advanced-options-button", 'data-action': 'click->reveal-component#hide', 'data-reveal-component-target': 'hideButton') do
      inline_svg_tag('icons/hide.svg') +
      content_tag(:div, text, class: 'text')
    end
  end

  def insert_sample_text_button(text)
    content_tag(:div, class:'insert-sample-text-button') do
      content_tag(:div, class: 'button', 'data-action': 'click->sample-text#annotator_recommender', 'data-sample-text': t("annotator.sample_text")) do
        content_tag(:div, text, class: 'text') +
        inline_svg_tag('icons/arrow-curved-up.svg')
      end
    end
  end

  def empty_state(text)
    content_tag(:div, class:'browse-empty-illustration') do
      inline_svg_tag('empty-box.svg') +
      content_tag(:p, text)
    end
  end


  def ontologies_selector(id:, label: nil, name: nil, selected: nil, placeholder: nil, multiple: true)
    content_tag(:div) do
      render(Input::SelectComponent.new(id: id, label: label, name: name, value: onts_for_select, multiple: multiple, selected: selected, placeholder: placeholder)) +
      content_tag(:div, class: 'ontologies-selector-button', 'data-controller': 'ontologies-selector', 'data-ontologies-selector-id-value': id) do
        content_tag(:div, t('ontologies_selector.clear_selection'), class: 'clear-selection', 'data-action': 'click->ontologies-selector#clear') +
        link_to_modal(t('ontologies_selector.ontologies_advanced_selection'), "/ontologies_selector?id=#{id}", data: { show_modal_title_value: t('ontologies_selector.ontologies_advanced_selection')})
      end
    end
  end

  def save_button_component(class_name: nil, id: , value:, data: nil, size: nil, type: nil)
    content_tag(:div, data: data, class: class_name) do
      render Buttons::RegularButtonComponent.new(id:id, value: value, variant: "primary", state: 'regular', size: size, type: type) do |btn|
        btn.icon_right do
          inline_svg_tag "check.svg"
        end
      end
    end
  end

  def cancel_button_component(class_name: nil, id: , value:, data: nil)
    content_tag(:div, data: data, class: class_name) do
      render Buttons::RegularButtonComponent.new(id:id, value: value, variant: "secondary", state: 'regular') do |btn|
        btn.icon_left do
          inline_svg_tag "x.svg"
        end
      end
    end
  end
 


end

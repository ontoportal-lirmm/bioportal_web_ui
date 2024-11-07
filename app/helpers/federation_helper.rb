module FederationHelper
  include ApplicationHelper

  def federated_portals
    $FEDERATED_PORTALS ||= LinkedData::Client.settings.federated_portals
  end

  def internal_portal_config(id)
    return unless internal_ontology?(id)

    {
      name: portal_name,
      api: rest_url,
      apikey: $API_KEY,
      ui: $UI_URL,
      color: "var(--primary-color)",
      'light-color': 'var(--light-color)',
    }
  end

  def federated_portal_config(name_key)
    federated_portals[name_key.to_sym]
  end

  def federated_portal_name(key)
    config = federated_portal_config(key)
    config ? config[:name] : key
  end

  def federated_portal_color(key)
    config = federated_portal_config(key)
    config[:color] if config
  end

  def federated_portal_light_color(key)
    config = federated_portal_config(key)
    config[:'light-color'] if config
  end

  def ontology_portal_config(id)
    rest_url = id.split('/')[0..-3].join('/')
    federated_portals.select { |_, config| config[:api].start_with?(rest_url) }.first
  end

  def ontology_portal_name(id)
    portal_key, _ = ontology_portal_config(id)
    portal_key ? federated_portal_name(portal_key) : nil
  end

  def ontology_portal_color(id)
    portal_key, _ = ontology_portal_config(id)
    federated_portal_color(portal_key) if portal_key
  end

  def ontoportal_ui_link(id)
    portal_key, config = ontology_portal_config(id)
    return nil unless portal_key

    ui_link = config[:ui]
    api_link = config[:api]

    id.gsub(api_link, "#{ui_link}/") rescue id
  end

  def internal_ontology?(id)
    id.start_with?(rest_url)
  end

  def federated_ontology?(id)
    !internal_ontology?(id)
  end

  def request_portals
    portals = RequestStore.store[:federated_portals] || []
    [portal_name] + portals
  end

  def request_portals_names(counts, time)
    output = request_portals.map do |x|
      config = federated_portal_config(x)

      if config
        name = config[:name]
        color = config[:color]
      elsif portal_name.downcase.eql?(x.downcase)
        name = portal_name
        color = nil
      else
        next nil
      end

      content_tag(:span, "#{federated_portal_name(name)} (#{counts[federated_portal_name(name).downcase]})", style: color ? "color: #{color}" : "", class: color ? "" : "text-primary")
    end.compact.join(", ")

    "#{output} in #{sprintf("%.2f", time)}s"
  end

  def federated_request?
    params[:portals]
  end

  def federation_enabled?
    !federated_portals.blank?
  end


  def federation_error?(response)
    !response[:errors].blank?
  end

  def federation_error(response)
    federation_errors = response[:errors].map { |e| ontology_portal_name(e.split(' ').last.gsub('search', '')) }
    federation_errors.map { |p| "#{p} #{t('federation.not_responding')} " }.join(' ')
  end

  def alert_message_if_federation_error(errors, &block)
    return if errors.blank?

    content_tag(:div, class: 'my-1') do
      render Display::AlertComponent.new(type: 'warning') do
        capture(&block)
      end
    end
  end

  def class_federation_configuration(class_object)
    is_external = federation_external_class?(class_object)
    portal_name = is_external ? helpers.portal_name_from_uri(class_object.links['ui']) : nil

    result = {
      portal_name: portal_name,
      portal_color: is_external ? federated_portal_color(portal_name) : nil,
      portal_light_color: is_external ? federated_portal_light_color(portal_name) : nil
    }
    result[:link] = class_object.links['ui'] if is_external
    result
  end

  def federation_external_class?(class_object)
    !class_object.links['self'].include?($REST_URL)
  end

  def canonical_ontology(ontologies)
    if ontologies.size.eql?(1)
      ontologies.first
    else
      internal_ontology = ontologies.select { |x| helpers.internal_ontology?(x[:id]) }.first
      if internal_ontology
        internal_ontology
      else
        external_canonical_ontology_portal(ontologies)
      end
    end
  end

  def federation_portal_status(portal_name: nil)
    Rails.cache.fetch("federation_portal_up_#{portal_name}", expires_in: 2.hours) do
      portal_api = federated_portals&.dig(portal_name,:api)
      return false unless portal_api
      portal_up = false
      begin
        response = Faraday.new(url: portal_api) do |f|
          f.adapter Faraday.default_adapter
          f.request :url_encoded
          f.options.timeout = 20
          f.options.open_timeout = 20
        end.head
        portal_up = response.success?
      rescue StandardError => e
        Rails.logger.error("Error checking portal status for #{portal_name}: #{e.message}")
      end
      portal_up
    end
  end

  def federation_chip_component(key, name, acronym, checked, portal_up)
    render TurboFrameComponent.new(id:"federation_portals_status_#{key}") do
      content_tag(:div, style: "cursor: default;") do
        title = "#{!portal_up ? "#{key.humanize.gsub('portal', 'Portal')} #{t('federation.not_responding')}" : ''}"
        group_chip_component(name: name,
                             object: { "acronym" => acronym, "value" => key },
                             checked: checked,
                             title: title ,
                             disabled: !portal_up)
      end
    end
  end

  def federation_input_chips(name: nil)
    federated_portals.map do |key, config|
      turbo_frame_component = TurboFrameComponent.new(
        id: "federation_portals_status_#{key}",
        src: "/status/#{key}?name=#{name}&acronym=#{config[:name]}&checked=#{request_portals.include?(key.to_s)}"
      )

      content_tag :div do
        render(turbo_frame_component) do |container|
          container.loader do
            render ChipsComponent.new(name: '', loading: true, tooltip: t('federation.check_status', portal: key.to_s.humanize.gsub('portal', 'Portal')))
          end
        end
      end
    end.join.html_safe
  end

  def init_federation_portals_status
    content_tag(:div, class: 'd-none') do
      federation_input_chips
    end
  end

  def federated_search_counts(search_results)
    ids = search_results.map do |result|
      result.dig(:root, :ontology_id) || rest_url
    end
    counts_ontology_ids_by_portal_name(ids)
  end

  def federated_browse_counts(ontologies)
    ids = ontologies.map { |ontology| ontology[:id] }
    counts_ontology_ids_by_portal_name(ids)
  end

  private

  def counts_ontology_ids_by_portal_name(portals_ids)
    counts = Hash.new(0)
    current_portal, *federation_portals = request_portals
    portals_ids.each do |id|
      counts[current_portal.downcase] += 1 if id.include?(current_portal.to_s.downcase)

      federation_portals.each do |portal|
        portal_api = federated_portals[portal.downcase.to_sym][:api]
        counts[portal.downcase] += 1 if id.include?(portal_api)
      end
    end

    counts
  end

  def external_canonical_ontology_portal(ontologies)
    canonical_portal = most_referred_portal(ontologies)
    ontologies.select{|o| o[:id].include?(canonical_portal.to_s)}.first
  end

  def most_referred_portal(ontology_submissions)
    portal_counts = Hash.new(0)
    ontology_submissions.each do |submission|
      federated_portals.keys.each do |portal|
        portal_counts[portal] += 1 if submission[:pullLocation]&.include?(portal.to_s)
      end
    end
    portal_counts.max_by { |_, count| count }&.first
  end

end

module FederationHelper

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

  def portal_name_from_uri(uri)
    URI.parse(uri).hostname.split('.').first
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
    federated_portals.select{|_, config| config[:api].start_with?(rest_url)}.first
  end

  def ontology_portal_name(id)
    portal_key, _ =  ontology_portal_config(id)
    portal_key ? federated_portal_name(portal_key) : nil
  end

  def ontology_portal_color(id)
    portal_key, _ =  ontology_portal_config(id)
    federated_portal_color(portal_key) if portal_key
  end

  def ontoportal_ui_link(id)
    portal_key, config =  ontology_portal_config(id)
    return nil  unless portal_key

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

  def request_portals_names(counts)
    request_portals.map do |x|
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

      content_tag(:span, "#{federated_portal_name(name)} (#{counts[federated_portal_name(name).downcase]})", style: color ? "color: #{color}" :  "", class: color ? "" : "text-primary")
    end.compact
  end

  def federation_enabled?
    params[:portals]
  end

  def federation_error?(response)
    !response[:errors].blank?
  end

  def federation_error(response)
    federation_errors = response[:errors].map{|e| ontology_portal_name(e.split(' ').last.gsub('search', ''))}
    federation_errors.map{ |p| "#{p} #{t('federation.not_responding')} " }.join(' ')
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

  def federated_search_counts(search_results)
    counts = Hash.new(0)

    search_results.each do |result|
      portal_name = result.dig(:root, :portal_name) || $SITE.downcase
      counts[portal_name] += 1
    end

    counts
  end

  def federated_browse_counts(ontologies)
    counts = Hash.new(0)

    ontologies.each do |ontology|
      current_portal, *federation_portals = request_portals

      counts[current_portal.downcase] += 1 if ontology[:id].include?(current_portal.to_s.downcase)

      federation_portals.each do |portal|
        counts[portal.downcase] += 1 if ontology[:id].include?(federated_portals[portal.downcase.to_sym][:api])
      end
    end

    counts
  end


  def federatation_enabled?
    params[:portals]
  end

  def is_federation_external_class(class_object)
    !class_object.links['self'].include?($REST_URL)
  end

  def portal_button(name: nil , color: nil , light_color: nil, link: nil, tooltip: nil)
    content_tag(:a, href: link, target: '_blank', 'data-controller': 'tooltip', title: tooltip, class: 'federation-portal-button button icon-right', style: color ? "background-color: #{light_color} !important" : '') do
      inline_svg_tag('logos/ontoportal.svg', class: "federated-icon-#{name.downcase}") +
      content_tag(:div, class: 'text', style: color ? "color: #{color} !important" : '') do
        name.humanize.gsub("portal", "Portal")
      end
    end
  end

  def find_portal_name_by_api(api_url)
    portal = federated_portals.values.find { |portal| portal[:api] == api_url }
    portal ? portal[:name] : nil
  end

  def federation_portal_status(portal_name: nil)
    Rails.cache.fetch("federation_portal_up_#{portal_name}", expires_in: 2.hours) do
      portal_api = federated_portals.dig(portal_name, :api)
      return false unless portal_api
      portal_up = false
      begin
        response = Faraday.new(url: portal_api) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
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
end

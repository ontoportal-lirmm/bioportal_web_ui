module FederationHelper

  def federated_portals
    $FEDERATED_PORTALS || {}
  end

  def federated_portal_config(name_key)
    $FEDERATED_PORTALS[name_key.to_sym]
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
    $FEDERATED_PORTALS.select{|_, config| config[:api].start_with?(rest_url)}.first
  end

  def ontology_portal_name(id)
    portal_key, _ =  ontology_portal_config(id)
    portal_key ? federated_portal_name(portal_key) : 'not found'
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
    id.start_with?(helpers.rest_url)
  end

  def federated_ontology?(id)
    !internal_ontology?(id)
  end

  def request_portals
    portals = RequestStore.store[:federated_portals] || []
    [portal_name] + portals
  end

  def request_portals_names
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

      content_tag(:span, federated_portal_name(name), style: color ? "color: #{color}" :  "", class: color ? "" : "text-primary")
    end.compact
  end
end

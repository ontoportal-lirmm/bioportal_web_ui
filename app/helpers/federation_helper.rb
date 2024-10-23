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

  def external_canonical_ontology_portal(ontologies)
    portal_counts = Hash.new(0)
    # Count occurrences of each portal in the pull_location URL
    ontologies.each do |ontology|
      federated_portals.keys.each do |portal|
        portal_counts[portal] += 1 if ontology[:pullLocation]&.include?(portal.to_s)
      end
    end
    # Determine the portal with the most occurrences
    portal = portal_counts.max_by { |_, count| count }&.first

    ontologies.select{|o| o[:id].include?(portal.to_s)}.first
  end

  def apply_canonical_portal(search_results, all_submissions)
    search_results.each do |result|
      next if result[:root][:portal_name].nil? || result[:root][:other_portals].blank?

      candidates = [result[:root][:link].split('?').first] + result[:root][:other_portals].map { |p| p[:link].split('?').first }

      portal_counts = Hash.new(0)

      candidates.each do |candidate|

        submission = all_submissions.find { |s| s.id&.include?(candidate.split('/').last) }

        if submission
          federated_portals.keys.each do |portal|
            portal_counts[portal] += 1 if submission[:pullLocation]&.include?(portal.to_s)
          end
        end
      end

      canonical_portal = portal_counts.max_by { |_, count| count }&.first
      next if canonical_portal.nil? || result[:root][:portal_name].eql?(canonical_portal.to_s)

      canonical_portal_result = result[:root][:other_portals].find { |r| r[:name] == canonical_portal.to_s }
      swap_portal_attributes(result[:root], canonical_portal_result) if canonical_portal_result
    end
    return search_results
  end

  def swap_portal_attributes(root_portal, new_portal)
    [:link, :portal_name, :portal_color, :portal_light_color].each do |attribute|
      root_portal[attribute], new_portal[attribute] = new_portal[attribute], root_portal[attribute]
    end
  end

end

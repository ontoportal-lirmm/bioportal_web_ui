module AgentHelper

  def agent_id_alert_container_id(agent_id, parent_id)
    "agents_alerts_#{agent_id_frame_id(agent_id, parent_id)}"
  end

  def agent_alert_container_id(agent, parent_id)
    agent_id_alert_container_id(agent_id(agent), parent_id)
  end

  def agent_alert_container(agent, parent_id)
    render_alerts_container(agent_alert_container_id(agent, parent_id))
  end

  def agent_id_alert_container(agent_id, parent_id)
    render_alerts_container(agent_alert_container_id(agent, parent_id))
  end

  def agent_table_line_id(id)
    "#{id}_table_item"
  end

  def agent_frame_id(agent, parent_id)
    agent_id_frame_id(agent_id(agent), parent_id)
  end

  def agent_id_frame_id(agent_id, parent_id)
    return 'application_modal_content' if parent_id.nil?

    return agent_id if parent_id.empty?

    "#{parent_id}_#{agent_id}"
  end

  def agent_id(agent)
    return  if agent.nil?

    agent_id = agent.is_a?(String) ? agent : agent.id
    agent_id ? agent_id.split('/').last : ''
  end

  def link_to_agent_edit_modal(agent, parent_id = nil)

    link_to_modal(nil, edit_agent_path(agent_id(agent), parent_id: parent_id, show_affiliations: parent_id.nil? || parent_id.empty?), class: 'btn btn-sm btn-light', data: { show_modal_title_value: "Edit agent #{agent.name}" }) do
      content_tag(:i, '', class: 'far fa-edit')
    end
  end

  def link_to_agent_edit(agent, parent_id, name_prefix, deletable: false, show_affiliations: true)
    link_to(edit_agent_path(agent_id(agent), name_prefix: name_prefix, deletable: deletable, parent_id: parent_id, show_affiliations: show_affiliations), class: 'btn btn-sm btn-light') do
      content_tag(:i, '', class: 'far fa-edit')
    end
  end


  def link_to_search_agent(id, parent_id , name_prefix, agent_type, deletable)
    link_to("/agents/show_search?id=#{id}&parent_id=#{parent_id}&agent_type=#{agent_type}&deletable=#{deletable}&name_prefix=#{name_prefix}", class: 'btn btn-sm btn-light') do
      inline_svg_tag "x.svg", width: "25", height: "25"
    end
  end

  def agent_search_input(id, agent_type, parent_id: , name_prefix:, deletable: false)
    render TurboFrameComponent.new(id: agent_id_frame_id(id, parent_id)) do
      render AgentSearchInputComponent.new(id: id, agent_type: agent_type,
                                           name_prefix: name_prefix,
                                           parent_id: parent_id, deletable: deletable,
                                           edit_on_modal: false)
    end
  end


  def affiliation?(agent)
    agent.agentType.eql?('organization')
  end

  def identifier_link(link, link_to: true)
    if link_to
      link_to(link, link, target: '_blank')
    else
      link
    end

  end

  def display_identifiers(identifiers, link: true)
    schemes_urls = { ORCID: 'https://orcid.org/', ISNI: 'https://isni.org/', ROR: 'https://ror.org/', GRID: 'https://www.grid.ac/' }
    Array(identifiers).map do |i|
      if i["schemaAgency"]
        schema_agency, notation = [i["schemaAgency"], i["notation"]]
      else
        schema_agency, notation = (i["id"] || i["@id"]).split('Identifiers/').last.delete(' ').split(':')
      end
      value = "#{schemes_urls[schema_agency.to_sym]}#{notation}"
      identifier_link(value, link_to: link)
    end.join(', ')
  end

  def agent_field_name(name, name_prefix = '')
    name_prefix&.empty? ? name : "#{name_prefix}[#{name}]"
  end

  def agent_identifier_name(index, name, name_prefix)
    agent_field_name("[identifiers][#{index}][#{name}]", name_prefix)
  end

  def new_affiliation_obj
    a = LinkedData::Client::Models::Agent.new
    a.agentType = 'organization'
    a.creator = session[:user].id
    a
  end

  def agent_usages(agent = @agent)
    usages = agent.usages.to_h
    usages.delete(:links)
    usages.delete(:context)
    usages
  end

  def agent_usages_count(agent = @agent)
    usages = agent_usages(agent)
    usages.values.flatten.size
  end

  def agents_metadata
    submission_metadata.select { |x| x["enforce"]&.include?('Agent') }.map do |x|
      SubmissionInputsHelper::SubmissionMetadataInput.new(attribute_key: x["attribute"], attr_metadata: x)
    end
  end
  def agents_metadata_attributes
    agents_metadata.map { |x| [x.attr, x.label] }
  end

  def agents_used_properties(agent)
    usages = agent_usages(agent)
    attributes = agents_metadata_attributes

    attributes.map do |attr, label|
      [attr, usages.select { |x, v| v.any? { |uri| uri[attr] } }.keys.map { |x| x.to_s.split('/')[-3] }]
    end.to_h
  end

  def agent_usage_errors_display(errors)
    content_tag(:div) do
      errors.map do |ont, message|
        content_tag(:p) do
          (content_tag(:strong, ont) + ' ontology is not valid, here are the errors: ' + agent_usage_error_display(message[:error])).html_safe
        end
      end.join.html_safe
    end
  end

  def agent_usage_error_display(error)
    error.map do |attr, details|
      details.values.join(', ').html_safe
    end.join('. ').html_safe
  end

  def display_agent(agent, link: true)
    agent_chip_component(agent)
  end

  def agent_tooltip(agent)
    name = agent.name
    email = agent.email
    type = agent.agentType 
    identifiers = display_identifiers(agent.identifiers, link: false)
    identifiers = orcid_number(identifiers)
    if agent.affiliations && agent.affiliations != []
      affiliations = ""
      agent.affiliations.each do |affiliation|
        affiliations = affiliations + affiliation.acronym + " "
      end
    end
    person_icon = inline_svg_tag 'icons/person.svg' , class: 'agent-type-icon'
    organization_icon = inline_svg_tag 'icons/organization.svg', class: 'agent-type-icon'
    ror_icon = inline_svg_tag 'icons/ror.svg', class: 'agent-dependency-icon ror'
    orcid_icon = inline_svg_tag 'icons/orcid.svg', class: 'agent-dependency-icon'
    agent_icon = type == "organization" ? organization_icon : person_icon
    identifiers_icon = type == "organization" ? ror_icon : orcid_icon
    tooltip_html = generate_agent_tooltip(agent_icon, name, email, identifiers, affiliations, identifiers_icon)
    return tooltip_html
  end

  def generate_agent_tooltip(agent_icon, name, email = nil, identifiers = nil, affiliations = nil, identifiers_icon = nil)
    content_tag(:div, class: 'agent-container') do
      content_tag(:div, agent_icon, class: 'agent-circle') +
      content_tag(:div) do
        content_tag(:div, name, class: 'agent-name') +
        content_tag(:div, email || '', class: 'agent-dependency') +
        unless identifiers.to_s.empty?
          content_tag(:div, class: 'agent-dependency') do
            identifiers_icon +
            identifiers || ''
          end
        end +
        unless affiliations.to_s.empty?
          content_tag(:div, class: 'agent-dependency') do
            inline_svg_tag('icons/organization.svg', class: 'agent-dependency-icon') +
            affiliations || ''
          end
        end
      end
    end
  end
  

  def agent_chip_component(agent)
    person_icon = inline_svg_tag 'icons/person.svg' , class: 'agent-type-icon'
    organization_icon = inline_svg_tag 'icons/organization.svg', class: 'agent-type-icon'
    agent_icon =  person_icon

    if agent.is_a?(String)
      name = agent
      title = nil
    else
      name = agent.name
      agent_icon = agent.agentType.eql?("organization") ? organization_icon : person_icon
      title = agent_tooltip(agent)
    end
    render_chip_component(title, agent_icon, name)
  end 


  def render_chip_component(title,agent_icon,name)
    render ChipButtonComponent.new(type: "static",'data-controller':' tooltip', title: title , class: 'text-truncate', style: 'max-width: 280px; display:block; line-height: unset') do 
      content_tag(:div, class: 'agent-chip') do
        content_tag(:div, agent_icon, class: 'agent-chip-circle') +
        content_tag(:div, name, class: 'agent-chip-name text-truncate')
      end   
    end 
  end

  def orcid_number(orcid)
    return orcid.split("/").last
  end


  
end

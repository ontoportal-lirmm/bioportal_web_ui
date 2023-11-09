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

    link_to_modal(nil, edit_agent_path(agent_id(agent), parent_id: parent_id, show_affiliations: parent_id.nil? || parent_id.empty?), class: 'btn btn-sm btn-light', data: { show_modal_title_value: "Edit agent #{agent.id}" }) do
      content_tag(:i, '', class: 'far fa-edit')
    end
  end

  def link_to_agent_edit(agent, parent_id = nil)
    link_to(edit_agent_path(agent_id(agent), parent_id: parent_id, show_affiliations: parent_id.nil? || parent_id.empty?), class: 'btn btn-sm btn-light') do
      content_tag(:i, '', class: 'far fa-edit')
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

  def display_agent(agent, link: true)
    return agent if agent.is_a?(String)

    out = agent.name.to_s
    identifiers = display_identifiers(agent.identifiers, link: link)
    out = "#{out} (#{identifiers})" unless identifiers.empty?
    affiliations = Array(agent.affiliations).map { |a| display_agent(a, link: link) }.join(', ')
    out = "#{out} (affiliations: #{affiliations})" unless affiliations.empty?
    out
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
end

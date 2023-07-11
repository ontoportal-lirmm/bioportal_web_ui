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
    agent_id = agent.id
    agent_id ? agent.id.split('/').last : ''
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

  def display_identifiers(identifiers)
    Array(identifiers).map { |i| "#{i["schemaAgency"]}:#{i["notation"]}" }.join(', ')
  end

  def display_agent(agent)
    agent.name + '(' + display_identifiers(agent.identifiers) + ')'
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
end

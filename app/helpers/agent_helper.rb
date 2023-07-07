module AgentHelper



  def affiliation?(agent)
    agent.agentType.eql?('organization')
  end


  def display_identifiers(identifiers)
    Array(identifiers).map {|i| "#{i["schemaAgency"]} / #{i["notation"]}"}.join(', ')
  end

  def agent_field_name(name, name_prefix='')
    name_prefix.empty?  ? name : "#{name_prefix}[#{name}]"
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

class AgentsController < ApplicationController
  include TurboHelper, AgentHelper
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]

  def index
    @agents = LinkedData::Client::Models::Agent.all(include: 'all')
  end

  def show
    # we use :agent_id not :id
    @agent = LinkedData::Client::Models::Agent.find(params[:agent_id])
    not_found("Agent with id #{params[:agent_id]}") if @agent.nil?

    @agent_id = params[:id] || agent_id(@agent)
    @name_prefix = params[:name_prefix]
    @edit_on_modal = params[:edit_on_modal]&.eql?('true')
    @deletable = params[:deletable]&.eql?('true')
  end

  def ajax_agents
    filters = { name: params[:name] }
    filters[:agentType] = params[:agent_type] if params[:agent_type]
    @agents = LinkedData::Client::Models::Agent.all(filters)
    agents_json = @agents.map do |x|
      {
        id: x.id,
        name: x.name,
        type: x.agentType,
        identifiers: x.identifiers.map { |i| "#{i.schemaAgency}:#{i.notation}" }.join(', ')
      }
    end

    render json: agents_json
  end

  def new
    @agent = LinkedData::Client::Models::Agent.new
    @agent.id = params[:id]
    @agent.creator = session[:user].id
    @agent.agentType = params[:type] || 'person'
    @agent.name = params[:name]
    @name_prefix = params[:name_prefix] || ''
    @show_affiliations = params[:show_affiliations].nil? || params[:show_affiliations]&.eql?('true')
  end

  def create
    new_agent = save_agent(agent_params)
    parent_id = params[:parent_id]
    name_prefix = params[:name_prefix]
    alert_id = agent_id_alert_container_id(params[:id], parent_id)

    if new_agent.errors
      render_turbo_stream alert_error(id: alert_id) { JSON.pretty_generate(response_errors(new_agent)) }
    else
      success_message = 'New Agent added successfully'
      streams = [alert_success(id: alert_id) { success_message }]

      streams << prepend('agents_table_content', partial: 'agents/show_line', locals: { agent: new_agent })
      streams << replace_agent_form(new_agent, agent_id: nil, frame_id: params[:id], parent_id: parent_id, name_prefix: name_prefix) if params[:parent_id]

      render_turbo_stream(*streams)
    end
  end

  def edit
    @agent = LinkedData::Client::Models::Agent.find("#{rest_url}/Agents/#{params[:id]}")
    @name_prefix = params[:parent_id] || ''
    @show_affiliations = params[:show_affiliations].nil? || params[:show_affiliations].eql?('true')
  end

  def show_search
    id = params[:id]
    parent_id = params[:parent_id]
    name_prefix = params[:name_prefix]
    agent_type = params[:agent_type]
    agent_deletable = params[:deletable].to_s.eql?('true')

    attribute_template_output = helpers.agent_search_input(id, agent_type,
                                                           parent_id: parent_id,
                                                           name_prefix: name_prefix,
                                                           deletable: agent_deletable)
    render_turbo_stream(replace(helpers.agent_id_frame_id(id, parent_id)) {  render_to_string(inline: attribute_template_output) } )

  end

  def update
    agent_update, agent = update_agent(params[:id].split('/').last, agent_params)

    parent_id = params[:parent_id]
    alert_id = agent_alert_container_id(agent, parent_id)

    if response_error?(agent_update)
      render_turbo_stream(alert_error(id: alert_id) { JSON.pretty_generate(response_errors(agent_update)) })
    else
      success_message = 'Agent successfully updated'
      table_line_id = agent_table_line_id(agent_id(agent))

      streams = [alert_success(id: alert_id) { success_message },
                 replace(table_line_id, partial: 'agents/show_line', locals: { agent: agent })
      ]

      streams << replace_agent_form(agent, parent_id: parent_id) if params[:parent_id]

      render_turbo_stream(*streams)
    end
  end

  def agent_usages
    @agent = find_agent_display_all
    @ontology_acronyms = LinkedData::Client::Models::Ontology.all(include: 'acronym', display_links: false, display_context: false, include_views: true).map(&:acronym)
    not_found("Agent with id #{@agent.id}") if @agent.nil?
    render partial: 'agents/agent_usage'
  end

  def update_agent_usages
    agent = find_agent_display_all
    responses, new_usages = update_agent_usages_action(agent, agent_usages_params)
    parent_id = params[:parent_id]
    alert_id = agent_alert_container_id(agent, parent_id)


    if responses.values.any? { |x| response_error?(x) }
      errors = {}
      responses.each do |ont, response|
        errors[ont.acronym] = response_errors(response) if response_error?(response)
      end

      render_turbo_stream(alert_error(id: alert_id) { helpers.agent_usage_errors_display(errors) })
    else

      success_message = 'Agent usages successfully updated'
      table_line_id = agent_table_line_id(agent_id(agent))
      agent.usages = new_usages
      streams = [alert_success(id: alert_id) { success_message },
                 replace(table_line_id, partial: 'agents/show_line', locals: { agent: agent })
      ]

      render_turbo_stream(*streams)
    end

  end

  def destroy
    error = nil
    @agent = LinkedData::Client::Models::Agent.find("#{rest_url}/Agents/#{params[:id]}")
    success_text = ''

    if @agent.nil?
      success_text = "Agent #{params[:id]} already deleted"
    else
      error_response = @agent.delete

      if response_error?(error_response)
        error = response_errors(error_response)
      else
        success_text = "Agent #{params[:id]} deleted successfully"
      end
    end

    respond_to do |format|
      format.turbo_stream do
        if error.nil?
          render turbo_stream: [
            alert(type: 'success') { success_text },
            turbo_stream.remove(agent_table_line_id(params[:id]))
          ]

        else
          render alert(type: 'danger') { error }
        end
      end
      format.html { render json: { success: success_text, error: error } }
    end

  end

  private

  def replace_agent_form(agent, agent_id: nil, frame_id: nil, parent_id:, partial: 'agents/agent_show', name_prefix: '')

    frame_id = frame_id ? agent_id_frame_id(frame_id, parent_id) : agent_frame_id(agent, parent_id)

    replace(frame_id, partial: partial, layout: false ,
            locals: { agent_id: agent_id, agent: agent, name_prefix: name_prefix, parent_id: parent_id,
                      edit_on_modal: false,
                      deletable: true})
  end

  def save_agent(params)
    agent = LinkedData::Client::Models::Agent.new(values: params)
    agent.creator = session[:user].id
    agent.save
  end

  def update_agent(id = params[:id], params)
    agent = LinkedData::Client::Models::Agent.find("#{rest_url}/Agents/#{id}")

    params[:creator] = session[:user].id if (agent.creator.nil? || agent.creator.empty?) && (params[:creator] || '').empty?

    res = agent.update(values: params)
    [res, agent.update_from_params(params)]
  end

  def update_agent_usages_action(agent, params)
    current_usages = helpers.agents_used_properties(agent)
    new_usages = params

    diffs = current_usages.keys.each_with_object({}) do |key, result|
      removed_values = current_usages[key] - Array(new_usages[key])
      added_values = Array(new_usages[key]) - current_usages[key]
      result[key] =  removed_values +  added_values
    end

    # changed_usages = new_usages.empty? ? current_usages :  new_usages.select { |x, v| !((current_usages[x] - v) + (v - current_usages[x])).empty? }


    changed_usages = diffs.reduce({}) do |h, attr_acronyms|
      attr, acronyms = attr_acronyms
      acronyms.each do |acronym|
        h[acronym] ||= []
        h[acronym] << attr
      end
      h
    end
    responses = {}
    changed_usages.each do |ontology, attrs|
      ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ontology).first
      sub = ontology.explore.latest_submission({ include: attrs.join(',') })
      values = {}
      attrs.each do |attr|
        current_val = sub.send(attr)
        if current_val.is_a?(Array)
          existent_agent = current_val.find_index { |x| x.id.eql?(agent.id) }
          if existent_agent
            current_val.delete_at(existent_agent)
          else
            current_val << agent
          end
          values[attr.to_sym] = current_val.map { |x| x.id }
        else
          values[attr.to_sym] = agent
        end
      end

      responses[ontology] = sub.update(values: values, cache_refresh_all: false)
    end

    [responses, new_usages]
  end

  def agent_usages_params
    p = params.permit(hasCreator: [], hasContributor: [], curatedBy: [], publisher: [], fundedBy: [], endorsedBy: [], translator: [])
    p.to_h
  end

  def agent_params
    p = params.permit(:agentType, :name, :email, :acronym, :homepage, :creator,
                      { identifiers: [:notation, :schemaAgency, :creator] },
                      { affiliations: [:id, :agentType, :name, :homepage, :acronym, :creator, { identifiers: [:notation, :schemaAgency, :creator] }] }
    )
    p = p.to_h
    p.transform_values do |v|
      if v.is_a? Hash
        v.values.reject(&:empty?)
      elsif v.is_a? Array
        v.reject(&:empty?)
      else
        v
      end
    end
    p[:identifiers] = (p[:identifiers] || {}).values
    p[:affiliations] = (p[:affiliations] || {}).values
    p[:affiliations].each do |affiliation|
      affiliation[:identifiers] = affiliation[:identifiers].values if affiliation.is_a?(Hash) && affiliation[:identifiers]
    end
    p
  end

  def find_agent_display_all(id = params[:id])
    # TODO fix in the api client, the find with params
    LinkedData::Client::Models::Agent.where({ display: 'all' }) do |obj|
      obj.id.to_s.eql?("#{rest_url}/Agents/#{id}")
    end.first
  end
end

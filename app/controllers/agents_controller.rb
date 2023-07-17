class AgentsController < ApplicationController
  include TurboHelper, AgentHelper
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]

  def index
    @agents = LinkedData::Client::Models::Agent.all
  end

  def show
    @agent = LinkedData::Client::Models::Agent.all(name: params[:name]).find { |x| x.name.eql?(params[:name]) }
    @agent_id = params[:id] || agent_id(@agent)
    @name_prefix = params[:name_prefix] ? "#{params[:name_prefix]}[#{params[:id]}]" : ''
    @edit_on_modal = params[:edit_on_modal]&.eql?('true')
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
    @new_agent = params[:new_agent].nil? || params[:new_agent].eql?('true')
    @name_prefix = params[:name_prefix] || ''
    @show_affiliations = params[:show_affiliations]&.eql?('true')
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

      streams << replace_agent_form(new_agent, frame_id: params[:id], parent_id: parent_id, name_prefix: name_prefix) if params[:parent_id]

      render_turbo_stream(*streams)
    end
  end

  def edit
    @agent = LinkedData::Client::Models::Agent.find("#{REST_URI}/Agents/#{params[:id]}")
    @name_prefix = params[:parent_id] || ''
    @show_affiliations = params[:show_affiliations].nil? || params[:show_affiliations].eql?('true')
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

  def destroy
    error = nil
    @agent = LinkedData::Client::Models::Agent.find("#{REST_URI}/Agents/#{params[:id]}")
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

  def replace_agent_form(agent, frame_id: nil, parent_id:, partial: 'agents/agent_show', name_prefix: '')

    frame_id = frame_id ? agent_id_frame_id(frame_id, parent_id) : agent_frame_id(agent, parent_id)

    replace(frame_id, partial: partial,
            locals: { agent: agent, name_prefix: name_prefix, parent_id: parent_id, edit_on_modal: false })
  end

  def save_agent(params)
    agent = LinkedData::Client::Models::Agent.new(values: params)
    agent.creator = session[:user].id
    agent.save
  end

  def update_agent(id = params[:id], params)
    agent = LinkedData::Client::Models::Agent.find("#{REST_URI}/Agents/#{id}")

    params[:creator] = session[:user].id if (agent.creator.nil? || agent.creator.empty?) && (params[:creator] || '').empty?

    res = agent.update(values: params)
    [res, agent.update_from_params(params)]
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
end

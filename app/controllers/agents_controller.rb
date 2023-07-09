class AgentsController < ApplicationController
  include TurboHelper
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]

  def index
    @agents = LinkedData::Client::Models::Agent.all
  end

  def show
    id = params[:id]&.eql?('fake_id') ? params[:name] : params[:id]
    @agent = LinkedData::Client::Models::Agent.all(name: id).find { |x| x.name.eql?(id) }
    @name_prefix = params[:parent_id] ? "[affiliations][#{params[:parent_id]}]" : ''
  end

  def ajax_agents
    @agents = LinkedData::Client::Models::Agent.all(name: params[:name], agentType: params[:organization_only]&.eql?('true') ? 'organization' : '')
    agents_json = @agents.map do |x|
      {
        id: x.id,
        name: x.name,
        type: x.agentType,
        identifiers: x.identifiers.map { |i| i.schemaAgency + ':' + i.notation }.join(', ')
      }
    end

    render json: agents_json
  end

  def new
    @agent = LinkedData::Client::Models::Agent.new
    @agent.creator = session[:user].id
    @agent.agentType = params[:type] || 'person'
    @agent.name = params[:name]
    @new_agent = params[:new_agent].nil? || params[:new_agent].eql?('true')
  end

  def create
    new_agent = save_agent(agent_params)
    if new_agent.errors
      render_turbo_stream alert_error { JSON.pretty_generate(response_errors(new_agent)) }
    else
      success_message = 'New Agent added successfully'
      render_turbo_stream(alert_success { success_message },
                          prepend('agents_table_content', partial: 'agents/show_line', locals: { agent: new_agent }))
    end
  end

  def edit
    @agent = LinkedData::Client::Models::Agent.find("#{REST_URI}/Agents/#{params[:id]}")
  end

  def update
    agent_update, agent = update_agent(params[:id].split('/').last, agent_params)

    if response_error?(agent_update)
      render_turbo_stream(alert_error { JSON.pretty_generate(response_errors(agent_update)) })
    else
      success_message = 'Agent successfully updated'
      render_turbo_stream(alert_success { success_message },
                          replace(agent.id.split('/').last, partial: 'agents/show_line', locals: { agent: agent }))
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
            turbo_stream.remove(params[:id])
          ]

        else
          render alert(type: 'danger') { error }
        end
      end
      format.html { render json: { success: success_text, error: error } }
    end

  end

  private

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
    p = params.permit(:agentType, :name, :email, :acronym, :homepage,
                      :creator,
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

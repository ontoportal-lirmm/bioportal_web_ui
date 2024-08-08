class AgentsController < ApplicationController
  include TurboHelper, AgentHelper
  before_action :authorize_and_redirect, :only => [:edit, :update, :create, :new]

  def index
    @agents = LinkedData::Client::Models::Agent.all(include: 'all')
  end

  def show
    # we use :agent_id not :id
    @agent = LinkedData::Client::Models::Agent.find(params[:agent_id].split('/').last)
    not_found(t('agents.not_found_agent', id: params[:agent_id])) if @agent.nil?

    @agent_id = params[:id] || agent_id(@agent)
    @name_prefix = params[:name_prefix]
    @edit_on_modal = params[:edit_on_modal]&.eql?('true')
    @deletable = params[:deletable]&.eql?('true')
  end

  def ajax_agents
    filters = { query: params[:query], qf: "identifiers_texts^20 acronym_text^15 name_text^10 email_text^10"}
    @agents = LinkedData::Client::HTTP.get('/search/agents', filters)
    agents_json = @agents.collection.map do |x|
      {
        id: x.resource_id,
        name: x.name_text,
        type: x.agentType_t,
        identifiers: x.identifiers_texts&.join(', '),
        acronym: x.acronym_text
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
    @deletable = params[:deletable]&.eql?('true')
  end

  def create
    new_agent = save_agent(agent_params)
    parent_id = params[:parent_id]
    name_prefix = params[:name_prefix]
    alert_id = agent_id_alert_container_id(params[:id], parent_id)
    deletable = params[:deletable]&.eql?('true')
    if new_agent.errors
      errors = generate_errors(response_errors(new_agent))
      render_turbo_stream alert_error(id: alert_id) { errors.join(', ') }
    else
      success_message = t('agents.add_agent')
      streams = [alert_success(id: alert_id) { success_message }]

      streams << prepend('admin_agents_table_body', partial: 'agents/agent', locals: { agent: new_agent })
      streams << replace_agent_form(new_agent, agent_id: nil, frame_id: params[:id],
                                    parent_id: parent_id, name_prefix: name_prefix,
                                    deletable: deletable
      ) if params[:parent_id]

      render_turbo_stream(*streams)
    end
  end

  def edit
    @agent = LinkedData::Client::Models::Agent.find(params[:id].split('/').last)
    @name_prefix = params[:name_prefix] || ''
    @show_affiliations = params[:show_affiliations].nil? || params[:show_affiliations].eql?('true')
    @deletable = params[:deletable].to_s.eql?('true')
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
    deletable = params[:deletable]&.eql?('true')
    if response_error?(agent_update)
      errors = generate_errors(response_errors(agent_update).values.first)
      render_turbo_stream alert_error(id: alert_id) { errors.join(', ') }
    else
      success_message = t('agents.update_agent')
      table_line_id = agent_table_line_id(agent_id(agent))
      agent = find_agent_display_all(agent.id.split('/').last)
      streams = [alert_success(id: alert_id) { success_message },
                 replace(table_line_id, partial: 'agents/agent', locals: { agent: agent })
      ]

      streams << replace_agent_form(agent, agent_id: agent_id(agent.id), name_prefix: params[:name_prefix] , parent_id: parent_id, deletable: deletable) if params[:parent_id]

      render_turbo_stream(*streams)
    end
  end

  def agent_usages
    @agent = find_agent_display_all
    @ontology_acronyms = LinkedData::Client::Models::Ontology.all(include: 'acronym', display_links: false, display_context: false, include_views: true).map(&:acronym)
    not_found(t('agents.not_found_agent', id: @agent.id)) if @agent.nil?
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

      success_message = t('agents.agent_usages_updated')
      table_line_id = agent_table_line_id(agent_id(agent))
      agent.usages = new_usages
      streams = [alert_success(id: alert_id) { success_message },
                 replace(table_line_id, partial: 'agents/agent', locals: { agent: agent })
      ]

      render_turbo_stream(*streams)
    end

  end

  def destroy
    error = nil
    @agent = LinkedData::Client::Models::Agent.find(params[:id].split('/').last)
    success_text = ''

    if @agent.nil?
      success_text = t('agents.agent_already_deleted', id: params[:id])
    else
      error_response = @agent.delete

      if response_error?(error_response)
        error = response_errors(error_response)
      else
        success_text = t('agents.agent_deleted_successfully', id: params[:id])
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
          render_turbo_stream alert(type: 'danger') { error }
        end
      end
      format.html { render json: { success: success_text, error: error } }
    end

  end

  private

  def replace_agent_form(agent, agent_id: nil, frame_id: nil, parent_id:, partial: 'agents/agent_show', name_prefix: '', deletable: true)

    frame_id = frame_id ? agent_id_frame_id(frame_id, parent_id) : agent_frame_id(agent, parent_id)

    replace(frame_id, partial: partial, layout: false ,
            locals: { agent_id: agent_id, agent: agent, name_prefix: name_prefix, parent_id: parent_id,
                      edit_on_modal: false,
                      deletable: deletable})
  end

  def save_agent(params)
    agent = LinkedData::Client::Models::Agent.new(values: params)
    agent.creator = session[:user].id
    agent.save
  end

  def update_agent(id = params[:id], params)
    agent = LinkedData::Client::Models::Agent.find(id)

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
          values[attr.to_sym] = agent.id
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
    p[:identifiers] = p[:identifiers].reject{ |key, value| value["notation"].empty? }
    identifiers_schemaAgency = params[:agentType].eql?('person') ? 'ORCID' : 'ROR'
    p[:identifiers]&.each_value do |identifier|
      identifier[:schemaAgency] = identifiers_schemaAgency
      if identifier[:schemaAgency].downcase.eql?('orcid')
        identifier[:notation] = normalize_orcid(identifier[:notation])
      else
        identifier[:notation] = normalize_ror(identifier[:notation])
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

  def normalize_orcid(orcid)
    case orcid
    when /\A\d{16}\z/
      # Case 1: 16 digits, add dashes
      orcid = orcid.scan(/.{1,4}/).join('-')

    when /\A\d{4}-\d{4}-\d{4}-\d{4}\z/
      orcid = orcid

    when /\Ahttps:\/\/(www\.)?orcid\.org\/\d{4}-\d{4}-\d{4}-\d{4}\z/
      # Case 3: ORCID URL (with or without "www."), extract the numbers with dashes
      orcid = orcid.split('/').last

    when /\Aorcid\.org\/\d{4}-\d{4}-\d{4}-\d{4}\z/
      # Case 4: ORCID without scheme (http/https)
      orcid = orcid.split('/').last

    when /\Awww\.orcid\.org\/\d{4}-\d{4}-\d{4}-\d{4}\z/
      # Case 5: ORCID with "www." without scheme
      orcid = orcid.split('/').last
    end

    return orcid
  end

  def normalize_ror(ror)
    case ror
    when /\A0\w{6}\d{2}\z/
      # Case 1: 9 characters, starting with '0', 6 alphanumeric, ending with 2 digits
      ror = ror

    when /\Ahttps:\/\/ror\.org\/(0\w{6}\d{2})\z/
      # Case 2: Full URL with 'https://ror.org/', extract the ROR ID
      ror = ror.split('/').last

    when /\Aror\.org\/(0\w{6}\d{2})\z/
      # Case 3: ROR without scheme (http/https), extract the ROR ID
      ror = ror.split('/').last
    end

    return ror
  end

  def generate_errors(response_errors)
    errors = []
    response_errors.values.each_with_index do |v, i|
      if v[:existence]
        errors << "#{response_errors.keys[i].capitalize} #{t('agents.errors.required')}"
      elsif v[:unique_identifiers]
        errors << t('agents.errors.used_identifier')
      elsif v[:no_url]
        errors << t('agents.errors.invalid_url')
      else
        errors << JSON.pretty_generate(response_errors)
      end
    end
    return errors
  end
end

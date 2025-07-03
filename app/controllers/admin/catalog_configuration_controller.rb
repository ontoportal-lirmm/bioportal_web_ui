class Admin::CatalogConfigurationController < ApplicationController
  before_action :authorize_admin
  before_action :load_catalog_metadata, only: [:show]
  before_action :load_catalog_data, only: [:show]

  CATALOG_PATH = "#{LinkedData::Client.settings.rest_url}/".freeze
  CATALOG_METADATA_URL = "#{LinkedData::Client.settings.rest_url}/catalog_metadata".freeze

  def show
    @catalog_groups = attributes_groups
    @catalog_metadata ||= session[:catalog_metadata] || load_catalog_metadata
    @catalog_data ||= session[:catalog_data] || load_catalog_data
  end

  def update
    config = sanitize_config_params

    if update_remote_config(config)
      flash.now[:notice] = true
    else
      flash.now[:alert] = true
    end

    @catalog_data = load_catalog_data
    session[:catalog_data] = @catalog_data
    @catalog_metadata = session[:catalog_metadata] || load_catalog_metadata
    @catalog_groups = attributes_groups
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'catalog-config',
          render_to_string('admin/catalog_configuration/show')
        )
      end
      format.html { redirect_to admin_api_configuration_index_path }
    end
  end

  def edit_nested_form
    # Use cached data from session, fallback to fresh fetch if needed
    @key = params[:key]&.to_sym
    return head :bad_request unless @key

    @catalog_data = session[:catalog_data] || load_catalog_data
    @catalog_metadata = session[:catalog_metadata] || load_catalog_metadata
    
    @value_attrs = @catalog_data&.dig(@key) || []
    @field_names = extract_field_names_for_key(@key)
    
    render partial: 'edit_nested_form_modal', layout: false
  end

  private

  def attributes_groups
    {
      general: %w[acronym title identifier versionInfo status],
      licensing: %w[accessRights rightsHolder license morePermissions],
      description: %w[
        description comment keyword alternative hiddenLabel 
        bibliographicCitation isReferencedBy
      ],
      dates: %w[created modified],
      persons_and_organizations: %w[
        creator contributor publisher contactPoint curatedBy 
        translator endorsedBy fundedBy funding
      ],
      community: %w[
        audience publishingPrinciples repository bugDatabase 
        mailingList toDoList award
      ],
      usage: %w[knownUsage coverage example],
      methodology_and_provenance: %w[accrualMethod accrualPeriodicity accrualPolicy],
      media: %w[associatedMedia depiction logo],
      other: %w[color federated_portals relation]
    }.freeze
  end

  def list_included_attributes
    attributes_groups.values.flatten.freeze
  end

  def agents_list
    %w[
      rightsHolder contactPoint creator contributor curatedBy 
      translator publisher endorsedBy
    ].freeze
  end

  def load_catalog_data
    return @catalog_data if @catalog_data

    params = build_catalog_params(exclude_agents: true)
    @catalog_data = LinkedData::Client::HTTP.get(CATALOG_PATH, params).to_hash
    agent_params = build_catalog_params(agents_only: true)
    catalog_agents = LinkedData::Client::HTTP.get(CATALOG_PATH, agent_params).to_hash
    @catalog_data.merge!(catalog_agents.to_hash)
    session[:catalog_data] = @catalog_data
    @catalog_data
  rescue StandardError => e
    handle_catalog_error(e, 'catalog data')
    @catalog_data = {}
    session[:catalog_data] = @catalog_data
    @catalog_data
  end

  def load_catalog_metadata
    return @catalog_metadata if @catalog_metadata

    catalog_metadata_list = LinkedData::Client::HTTP.get(CATALOG_METADATA_URL, {})
    filtered_metadata = catalog_metadata_list.select do |metadata| 
      list_included_attributes.include?(metadata.attribute) 
    end
    
    @catalog_metadata = filtered_metadata.index_by(&:attribute)
    session[:catalog_metadata] = @catalog_metadata
    @catalog_metadata
  rescue StandardError => e
    @catalog_metadata = {}
    session[:catalog_metadata] = @catalog_metadata
    @catalog_metadata
  end

  def build_catalog_params(exclude_agents: false, agents_only: false)
    included_attrs = if agents_only
                      agents_list
                    elsif exclude_agents
                      list_included_attributes - agents_list
                    else
                      list_included_attributes
                    end

    {
      include: included_attrs.join(','),
      display_links: false,
      display_context: false,
      _ts: Time.current.to_i
    }
  end

  def update_remote_config(config)
    response = LinkedData::Client::HTTP.patch(CATALOG_PATH, config)
    response.status == 200
  rescue StandardError => e
    Rails.logger.error("Config update failed: #{e.message}")
    false
  end

  def sanitize_config_params
    config = params.require(:config).permit!.to_h

    list_included_attributes.each do |key|
      config[key] = sanitize_attribute_value(config[key.to_s])
    end

    config['rightsHolder'] = config['rightsHolder']&.first&.presence || '' if config['rightsHolder']

    config.compact
  end

  def sanitize_attribute_value(raw_value)
    return nil if raw_value.nil?

    case raw_value
    when Hash
      raw_value.values.filter_map { |v| v.is_a?(Hash) ? v['id'] : nil }
    when Array
      raw_value.reject(&:blank?)
    else
      raw_value
    end
  end

  def extract_field_names_for_key(key)
    metadata = @catalog_metadata[key.to_s]
    return [] unless metadata&.enforcedValues
    
    metadata.enforcedValues.flat_map do |field|
      field.to_h.keys - [:links, :context]
    end
  end


end
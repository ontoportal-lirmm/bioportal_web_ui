module Admin
  class ApiConfigurationController < ApplicationController
    before_action :authorize_admin
    before_action :load_catalog_metadata, only: [:index]
    before_action :load_catalog_data, only: [:index]

    CATALOG_PATH = "#{LinkedData::Client.settings.rest_url}/"
    CATALOG_METADATA_URL = "#{LinkedData::Client.settings.rest_url}/catalog_metadata"

    def index
      render 'index', locals: {
        attributes_groups: attributes_groups,
        attributes_metadata: @catalog_metadata, 
        attributes_values: @catalog_data
      }
    end

    def update
      config = sanitize_config_params

      if update_remote_config(config)
        flash.now[:notice] = true
      else
        flash.now[:alert] = true
      end
      
      @catalog_data = load_catalog_data # Refresh data after update
      session[:catalog_data] = @catalog_data # Update session cache
      @catalog_metadata = session[:catalog_metadata] || load_catalog_metadata

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "api-config", 
            render_to_string("admin/api_configuration/index", locals: {
              attributes_groups: attributes_groups,
              attributes_metadata: @catalog_metadata,
              attributes_values: @catalog_data
            })
          )
        end
        format.html { redirect_to admin_api_configuration_index_path }
      end
    end

    def edit_nested_form
      # Use cached data from session, fallback to fresh fetch if needed
      @catalog_data = session[:catalog_data] || load_catalog_data
      @catalog_metadata = session[:catalog_metadata] || load_catalog_metadata
      
      @key = params[:key].to_sym
      @value_attrs = @catalog_data&.dig(@key) || []
      @field_names = extract_field_names_for_key(@key)
      
      render partial: 'edit_nested_form_modal', layout: nil
    end

    private

    def attributes_groups
      {
        general: %w[acronym title identifier versionInfo status],
        licensing: %w[accessRights rightsHolder license morePermissions],
        description: %w[description comment keyword alternative hiddenLabel bibliographicCitation isReferencedBy],
        dates: %w[created modified],
        persons_and_organizations: %w[creator contributor publisher contactPoint curatedBy translator endorsedBy fundedBy funding],
        community: %w[audience publishingPrinciples repository bugDatabase mailingList toDoList award],
        usage: %w[knownUsage coverage example],
        methodology_and_provenance: %w[accrualMethod accrualPeriodicity accrualPolicy],
        media: %w[associatedMedia depiction logo],
        other: %w[color federated_portals relation]
      }
    end

    def list_included_attributes
      attributes_groups.values.flatten
    end

    def load_catalog_data
      params = { 
        include: (list_included_attributes).join(','),
        display_links: false, 
        display_context: false,
        _ts: Time.now.to_i
      }
      @catalog_data = LinkedData::Client::HTTP.get(CATALOG_PATH, params).to_hash
      session[:catalog_data] = @catalog_data # Cache in session for popup usage
    rescue StandardError => e
      Rails.logger.error("Failed to load catalog metadata: #{e.message}")
      @catalog_data = []
      session[:catalog_data] = @catalog_data
    end

    def load_catalog_metadata
      catalog_metadata_list = LinkedData::Client::HTTP.get(CATALOG_METADATA_URL, {})
      filtered = catalog_metadata_list.select { |metadata| list_included_attributes.include?(metadata.attribute) }
      @catalog_metadata = filtered.index_by(&:attribute)
      session[:catalog_metadata] = @catalog_metadata # Cache in session for popup usage
    rescue StandardError => e
      Rails.logger.error("Failed to load catalog metadata: #{e.message}")
      @catalog_metadata = []
      session[:catalog_metadata] = @catalog_metadata
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
        raw_value = config[key.to_s]
        next if raw_value.nil?

        # Handle hash of indexed agent objects
        if raw_value.is_a?(Hash)
          config[key] = raw_value.values.map do |v|
            v.is_a?(Hash) ? v["id"] : nil
          end.compact
        end

        # Handle regular arrays (remove blanks)
        if raw_value.is_a?(Array)
          config[key] = raw_value.reject(&:blank?)
        end
      end

      config["rightsHolder"] = config["rightsHolder"][0] if config["rightsHolder"].present?

      config
    end


    def extract_field_names_for_key(key)
      metadata = @catalog_metadata[key.to_s]
      return [] unless metadata&.enforcedValues
      
      metadata.enforcedValues.flat_map do |field|
        field.to_h.keys - [:links, :context]
      end
    end

  end
end
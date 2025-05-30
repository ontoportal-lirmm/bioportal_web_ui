module Admin
  class ApiConfigurationController < ApplicationController
    before_action :authorize_admin
    before_action :load_catalog_metadata, only: [:index]
    before_action :load_catalog_data, only: [:index]

    CATALOG_PATH = "#{LinkedData::Client.settings.rest_url}/"
    CATALOG_METADATA_URL = "#{LinkedData::Client.settings.rest_url}/catalog_metadata"
    ATTRIBUTES_TO_INCLUDE = %w[
      acronym title color description identifier status accessRights 
      keyword license landingPage created federated_portals fundedBy
    ].freeze

    def index
      render 'index', locals: { 
        attributes_metadata: @catalog_metadata, 
        attributes_values: @catalog_data 
      }
    end

    def update
      config = sanitize_config_params
      
      if update_remote_config(config)
        flash.now[:notice] = true
        @catalog_data = load_catalog_data # Refresh data after update
        session[:catalog_data] = @catalog_data # Update session cache
      else
        flash.now[:alert] = true
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "api-config", 
            render_to_string("admin/api_configuration/index", locals: {
              attributes_metadata: session[:catalog_metadata], 
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

    def load_catalog_data
      params = { 
        include: ATTRIBUTES_TO_INCLUDE.join(','), 
        display_links: false, 
        display_context: false 
      }
      @catalog_data = LinkedData::Client::HTTP.get(CATALOG_PATH, params).to_hash
      session[:catalog_data] = @catalog_data # Cache in session for popup usage
    rescue StandardError => e
      Rails.logger.error("Failed to load catalog metadata: #{e.message}")
      @catalog_metadata = []
      session[:catalog_metadata] = @catalog_metadata
    end

    def load_catalog_metadata
      catalog_metadata_list = LinkedData::Client::HTTP.get(CATALOG_METADATA_URL, {})
      @catalog_metadata = catalog_metadata_list.select { |metadata| ATTRIBUTES_TO_INCLUDE.include?(metadata.attribute) }
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

    # This method sanitizes the config parameters before sending them to the API.
    # we are handling the attributes that are expected to be lists because they can have multiple entries
    # and we need to ensure they are processed correctly
    def sanitize_config_params
      config = params.require(:config).permit!.to_h
      
      %w[federated_portals fundedBy].each do |key|
        next unless config.key?(key)
        
        config[key] = process_list_attribute(config[key])
      end
      
      config
    end

    # Processes attributes that are expected to be lists due to it's format
    # fromat returned from the modal is like this: { "federated_portals": { "empty": true, "value": ["0" => {...}, "1" => {...}] } }
    def process_list_attribute(attribute_data)
      return [] if attribute_data.keys == ["empty"]
      
      attribute_data.to_h
                   .reject { |k, _| k == "empty" }
                   .values
                   .map(&:to_h)
    end

    # this is for extracting field names from the metadata enforcedValues of the key (federated_portals, fundedBy)
    def extract_field_names_for_key(key)
      metadata = @catalog_metadata.find { |m| m.attribute.to_sym == key }
      return [] unless metadata&.enforcedValues
      
      metadata.enforcedValues.flat_map do |field|
        field.to_h.keys - [:links, :context]
      end
    end

  end
end
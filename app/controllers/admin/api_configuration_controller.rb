module Admin
  class ApiConfigurationController < ApplicationController
    before_action :set_metadata

    def index
      root_url = "#{rest_url}/?display=all"
      attributes_values = LinkedData::Client::HTTP.get(root_url, {display: :all})
      render 'index', locals: { attributes_metadata: @catalog_metadata, attributes_values: attributes_values.to_h}
    end

    def update_api_configs
      updated_config = params.require(:config).permit!

      @boolean_attributes.map(&:attribute).each do |key|
        updated_config[key] = ActiveModel::Type::Boolean.new.cast(updated_config[key]) if updated_config.key?(key)
      end
      
      success = update_remote_config(updated_config.to_h)

      if success
        flash.now[:notice] = true if success
      else
        flash.now[:alert] = true unless success
      end
    
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("api-config", render_to_string("admin/api_configuration/index", locals: { attributes_metadata: @catalog_metadata, attributes_values: updated_config.to_h}))
        end
        format.html { redirect_to admin_api_configuration_index_path }
      end
    end

    def set_metadata
      root_url = "#{rest_url}/catalog_metadata"
      catalog_metadata = LinkedData::Client::HTTP.get(root_url, {})
    
      @catalog_metadata = []
      @string_attributes = []
      @url_attributes = []
      @boolean_attributes = []
      @date_attributes = []
    
      catalog_metadata.each do |attr_metadata|
        enforce_values = Array(attr_metadata.enforce)
    
        @catalog_metadata << attr_metadata if enforce_values.any? { |v| %w[string url boolean date integer].include?(v) }
        @string_attributes << attr_metadata if enforce_values.include?("string")
        @url_attributes << attr_metadata if enforce_values.include?("url")
        @boolean_attributes << attr_metadata if enforce_values.include?("boolean")
        @date_attributes << attr_metadata if enforce_values.include?("date")
      end
    end
    

    private

    def update_remote_config(new_config)
      api_url = "#{rest_url}/"
      response = LinkedData::Client::HTTP.patch(api_url, new_config)
      response.status == 204
    rescue StandardError => e
      Rails.logger.error("Config update failed: #{e.message}")
      false
    end

  end
end

class NotificationsController < ApplicationController
  def index
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 5
    
    begin
      # Fetch notifications from the API
      url = "#{rest_url}/notifications"
      # Using page_size instead of size, as it is more common in this codebase
      response = LinkedData::Client::HTTP.get(url, { page: page, page_size: per_page, apikey: get_apikey })

      if response.is_a?(Array) || (response.respond_to?(:collection) && response.collection.nil?)
        # Handle array response
        all_items = response.is_a?(Array) ? response : (response.respond_to?(:collection) ? [] : response)
        
        # Enforce per_page limit client-side if API returns more
        @notifications = all_items.take(per_page)
        
        # Simple pagination inference: if we got at least per_page items, assume next page
        # Note: accurate pagination with flat array response requires knowing total count or getting full list
        @next_page = all_items.size >= per_page ? page + 1 : nil
      elsif response && response.collection
        @notifications = response.collection
        if response.respond_to?(:page)
          total_pages = response.page.totalPages.to_i
          @next_page = page < total_pages ? page + 1 : nil
        else
          @next_page = response.collection.size >= per_page ? page + 1 : nil
        end
      else
        @notifications = []
        @next_page = nil
      end
    rescue => e
      Rails.logger.error "Failed to fetch notifications: #{e.message}"
      @notifications = []
      @next_page = nil
    end
    @current_page = page
  end

  def status
    begin
      # Fetch status from the API
      url = "#{rest_url}/notifications/status"
      response = LinkedData::Client::HTTP.get(url, { apikey: get_apikey })
      
      @status = {
        has_unseen: response.has_unseen,
        count: response.count
      }
    rescue => e
      Rails.logger.error "Failed to fetch notification status: #{e.message}"
      @status = { has_unseen: false, count: 0 }
    end
    render layout: false
  end
end

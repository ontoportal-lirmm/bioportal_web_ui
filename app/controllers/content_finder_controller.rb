require 'faraday'
class ContentFinderController < ApplicationController

    layout :determine_layout
  
    def index
        if params[:acronym] && params[:uri]
            @acronym = params[:acronym]
            @format = params[:output_format]
            case params[:output_format]
            when 'json'
              accept_header = "application/json"
            when 'xml'
              accept_header = "application/xml"
            when 'ntriples'
              accept_header = "application/n-triples"
            when 'turtle'
              accept_header = "text/turtle"
            end

            url = URI.parse("#{rest_url}/ontologies/#{params[:acronym].strip}/resolve/#{helpers.escape(params[:uri].strip)}")
            conn = Faraday.new(url: url) do |faraday|
              faraday.headers['Accept'] = accept_header
              faraday.adapter Faraday.default_adapter
              faraday.headers['Authorization'] = "apikey token=#{API_KEY}"
            end
            
            response = conn.get
            @result=""
            if response.success?
                @result = response.body.force_encoding(Encoding::UTF_8)
            end
        end
        render 'content_finder/index'
    end
end
class ContentFinderController < ApplicationController

    layout :determine_layout
  
    def index
        if params[:acronym] && params[:uri]
            @acronym = params[:acronym]
            @format = params[:output_format]

            url = URI.parse("#{rest_url}/ontologies/#{params[:acronym].strip}/resolve/#{helpers.escape(params[:uri].strip)}")
            http = Net::HTTP.new(url.host, url.port)
            http.use_ssl = true if url.scheme == 'https'
            request = Net::HTTP::Get.new(url)
            request.body = "apikey=#{API_KEY}"
    
            case params[:output_format]
            when 'json'
              request['Accept'] = "application/json"
            when 'xml'
              request['Accept'] = "application/xml"
            when 'ntriples'
              request['Accept'] = "application/n-triples"
            when 'turtle'
              request['Accept'] = "text/turtle"
            end
            response = http.request(request)
            @result = ""
            if response.code == '200'
              @result = response.body.force_encoding(Encoding::UTF_8)
            end
        end
        render 'content_finder/index'
    end
end
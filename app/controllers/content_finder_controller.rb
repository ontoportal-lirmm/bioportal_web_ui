class ContentFinderController < ApplicationController

    layout :determine_layout
  
    def index
        if params[:acronym] && params[:uri]
            @acronym = params[:acronym]
            ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:acronym]).first
            sub = ontology.explore.latest_submission({ include: 'submissionId' })
            params[:output_format] = params[:output_format].presence || 'json'
            params[:acronym] = sub.id.gsub(REST_URI, 'http://data.bioontology.org/')
            if params[:output_format] == 'html'
                params[:output_format] = 'json'
            end
            @format = params[:output_format]
            if params[:output_format] == 'json'
                @result = LinkedData::Client::HTTP.post("/dereference_resource", params).to_h.to_json
            else
                @result = LinkedData::Client::HTTP.post("/dereference_resource", params)
            end
        end
        render 'content_finder/index'
    end
end
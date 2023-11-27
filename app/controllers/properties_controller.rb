class PropertiesController < ApplicationController
    def show
        @property =  LinkedData::Client::HTTP.get("/ontologies/#{params[:acronym]}/properties/#{helpers.encode_param(params[:id])}")

        @acronym = params[:acronym]
        render partial: 'show' 
    end
end

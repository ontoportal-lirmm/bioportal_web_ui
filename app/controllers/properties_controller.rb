class PropertiesController < ApplicationController
    def show
        @data = JSON.parse(params[:data])
        @acronym = params[:acronym]
        respond_to do |format|
            format.html { render partial: 'show' }
        end 
    end
end

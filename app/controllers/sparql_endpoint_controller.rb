class SparqlEndpointController < ApplicationController
  layout :determine_layout
  
  include SparqlHelper

  def index
    
  end

  def edit_sample_queries
    @sample_queries = params[:sample_queries]  ? params[:sample_queries] : helpers.get_catalog_sample_queries
    @graph = params[:graph]
    render partial: 'sample_queries_edit_modal',layout: false
  end
end
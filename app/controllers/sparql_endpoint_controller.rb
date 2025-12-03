class SparqlEndpointController < ApplicationController
  layout :determine_layout
  before_action :check_sparql_enabled
  
  include SparqlHelper
  def index
  end

  def edit_sample_queries
    if params[:graph].nil?
      @sample_queries = helpers.get_catalog_sample_queries
    else
      @sample_queries = helpers.get_ontology_sample_queries(params[:graph])
      @graph = params[:graph].gsub($REST_URL, 'http://data.bioontology.org')
    end
    render partial: 'sample_queries_edit_modal',layout: false
  end

  private

  def check_sparql_enabled
    unless helpers.sparql_enabled?
      redirect_to root_path, alert: 'SPARQL endpoint is not available'
    end
  end
end
require 'faraday'

class ContentFinderController < ApplicationController
  include OntologyContentSerializer

  def index
    @result, _ = serialize_content(ontology_acronym: params[:acronym],
                                concept_id: params[:uri],
                                format: params[:output_format])
    render 'content_finder/index', layout: 'tool'
  end
end
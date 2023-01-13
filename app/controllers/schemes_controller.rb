class SchemesController < ApplicationController
  include SchemesHelper

  def show
    @scheme = get_request_scheme
  end

  def show_label
    scheme = get_request_scheme
    scheme_label = scheme ? scheme['prefLabel'] : params[:id]
    scheme_label = scheme_label.nil? || scheme_label.empty? ? params[:id] : scheme_label

    render LabelLinkComponent.inline(params[:id], scheme_label)
  end

  private

  def get_request_scheme
    params[:id] = params[:id] ? params[:id] : params[:scheme_id]
    params[:ontology_id] = params[:ontology_id] ? params[:ontology_id] : params[:ontology]

    if params[:id].nil? || params[:id].empty?
      render :text => "Error: You must provide a valid scheme id"
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    ontology_not_found(params[:ontology_id]) if @ontology.nil?
    get_scheme(@ontology, params[:id])
  end
end

class SchemesController < ApplicationController
  include SchemesHelper, SearchContent


  def index
    acronym = params[:ontology]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    ontology_not_found(acronym) if @ontology.nil?
    @submission_latest = @ontology.explore.latest_submission(include: 'all', invalidate_cache: invalidate_cache?) rescue @ontology.explore.latest_submission(include: '')

    @schemes = get_schemes(@ontology)

    if params[:search].blank?
      render partial: 'schemes/tree_view'
    else
      render_search_paginated_list(container_id: 'schemes_sorted_list',
                            types: ['ConceptScheme'],
                            next_page_url: "/ontologies/#{@ontology.acronym}/schemes",
                            child_url: "/ontologies/#{@ontology.acronym}/schemes/show",
                            child_param: :schemeid,
                            child_turbo_frame: 'scheme')
    end
  end

  def show
    @scheme = get_request_scheme
  end

  def show_label
    scheme = get_request_scheme
    scheme_label = scheme ? scheme['prefLabel'] : params[:id]
    scheme_label = scheme_label.nil? || scheme_label.empty? ? params[:id] : scheme_label

    render LabelLinkComponent.inline(params[:id], helpers.main_language_label(scheme_label))
  end

  private

  def get_request_scheme
    params[:id] = params[:id] ? params[:id] : params[:scheme_id]
    params[:ontology_id] = params[:ontology_id] ? params[:ontology_id] : params[:ontology]

    if params[:id].nil? || params[:id].empty?
      render :text => t('schemes.error_valid_scheme_id')
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    ontology_not_found(params[:ontology_id]) if @ontology.nil?
    get_scheme(@ontology, params[:id])
  end
end

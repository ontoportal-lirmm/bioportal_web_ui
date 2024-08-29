class SchemesController < ApplicationController
  include SchemesHelper, SearchContent


  def index
    acronym = params[:ontology]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    ontology_not_found(acronym) if @ontology.nil?
    @submission_latest = @submission = @ontology.explore.latest_submission(include: 'all')

    if params[:search].blank?
      @schemes = get_schemes(@ontology)

      render partial: 'schemes/tree_view'
    else
      query, page, page_size = helpers.search_content_params

      results, _, next_page, total_count = search_ontologies_content(query: query,
                                                                     page: page,
                                                                     page_size: page_size,
                                                                     filter_by_ontologies: [acronym],
                                                                     filter_by_types: ['ConceptScheme'])


      render inline: helpers.render_search_paginated_list(container_id: 'schemes_sorted_list',
                         next_page_url: "/ontologies/#{@ontology.acronym}/schemes",
                         child_url: "/ontologies/#{@ontology.acronym}/schemes/show", child_turbo_frame: 'scheme',
                         child_param: :schemeid,
                         results:  results, next_page:  next_page, total_count: total_count)

    end
  end

  def show
    redirect_to(ontology_path(id: params[:ontology_id], p: 'schemes', schemeid: params[:id],lang: request_lang)) and return unless turbo_frame_request?

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
    params[:id] = params[:id] ? params[:id] : params[:schemeid]
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

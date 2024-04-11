class CollectionsController < ApplicationController
  include CollectionsHelper,SearchContent


  def index
    acronym = params[:ontology]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    ontology_not_found(acronym) if @ontology.nil?

    @collections = get_collections(@ontology)
    collection_id = params[:collection_id]
    @collection = get_collection(@ontology, collection_id) if collection_id


    if params[:search].blank?
      render partial: 'collections/list_view'
    else

      render_search_paginated_list(container_id: 'collections_sorted_list',
                                   types: ['Collection'],
                                   next_page_url: "/ontologies/#{@ontology.acronym}/collections",
                                   child_url: "/ontologies/#{@ontology.acronym}/collections/show",
                                   child_param: :collectionid,
                                   child_turbo_frame: 'collection')
    end
  end

  def show
    @collection = get_request_collection
  end

  def show_label
    collection_label = ''
    collection  = get_request_collection
    collection_label =  collection['prefLabel'] if collection
    collection_label = params[:id]  if collection_label.nil? || collection_label.empty?

    render LabelLinkComponent.inline(params[:id], helpers.main_language_label(collection_label))
  end

  def show_members
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id] || params[:ontology]).first
    @collection = get_request_collection
    page = params[:page] || '1'
    @auto_click = page.to_s.eql?('1')
    @page = @collection.explore.members({page: page, language: request_lang})
    @concepts = @page.collection
    if @ontology.nil?
      ontology_not_found params[:ontology]
    else
      render partial: 'concepts/list'
    end
  end

  private

  def get_request_collection
    params[:id] = request_collection_id

    if params[:id].nil? || params[:id].empty?
      render plain: t('collections.error_valid_collection')
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id] || params[:ontology]).first
    ontology_not_found(params[:ontology_id]) if @ontology.nil?
    get_collection(@ontology, params[:id])
  end
end

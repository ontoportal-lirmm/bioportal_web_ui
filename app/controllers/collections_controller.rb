class CollectionsController < ApplicationController
  include CollectionsHelper
  def show
    @collection = get_request_collection
  end

  def show_label
    collection_label = ''
    collection  = get_request_collection
    collection_label =  collection['prefLabel'] if collection
    collection_label = params[:id]  if collection_label.nil? || collection_label.empty?

    render LabelLinkComponent.inline(params[:id], collection_label)
  end

  def show_members
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    @collection = get_request_collection
    page = params[:page] || '1'
    @auto_click = page.to_s.eql?('1')
    @page = @collection.explore.members({page: page})
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
      render plain: 'Error: You must provide a valid collection id'
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id] || params[:ontology]).first
    ontology_not_found(params[:ontology_id]) if @ontology.nil?
    get_collection(@ontology, params[:id])
  end
end

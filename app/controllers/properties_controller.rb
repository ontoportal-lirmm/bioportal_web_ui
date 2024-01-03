class PropertiesController < ApplicationController
    include TurboHelper

  def show
    @property = get_property(params[:id])
    @acronym = params[:acronym]
    render partial: 'show'
  end

  def show_tree
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology]).first
    ontology_not_found(params[:ontology]) if @ontology.nil?
    @root = OpenStruct.new({children: property_roots(params[:ontology])})
    not_found(@root.children.errors.join) if @root.children.respond_to?(:errors)

    if params[:propertyid]
        @property = get_property(params[:propertyid])
    else
        @property ||= @root.children.first
    end

    render inline: helpers.property_tree_component(@root, @property,
                                                   @ontology.acronym, request_lang,
                                                   id: 'properties_tree_view', auto_click: true)
  end


  def show_children
      acronym = params[:ontology]
      id = params[:propertyid]
      @property = get_property(id, acronym)
      @property.children = property_children(id, acronym)

      render turbo_stream: [
        replace(helpers.child_id(@property) + '_open_link') { TreeLinkComponent.tree_close_icon },
        replace(helpers.child_id(@property) + '_childs') do
            helpers.property_tree_component(@property, @property, acronym, request_lang, sub_tree: true)
        end
      ]
  end


  private
  def get_property(id, acronym = params[:acronym])
      LinkedData::Client::HTTP.get("/ontologies/#{acronym}/properties/#{helpers.encode_param(id)}")
  end

  def property_roots(acronym = params[:acronym])
      LinkedData::Client::HTTP.get("/ontologies/#{acronym}/properties/roots")
  end

  def property_children(id, acronym = params[:acronym])
      LinkedData::Client::HTTP.get("/ontologies/#{acronym}/properties/#{helpers.encode_param(id)}/children?display=all")
  end

end

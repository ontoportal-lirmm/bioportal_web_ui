class InstancesController < ApplicationController

  def index_by_ontology
    logger.debug params[:ontology].inspect
    custom_render LinkedData::Client::HTTP.get("/ontologies/#{params[:ontology]}/instances", get_query_parameters , raw:true)
  end

  def index_by_class
    custom_render LinkedData::Client::HTTP
                    .get("/ontologies/#{params[:ontology]}/classes/#{CGI.escape(params[:class])}/instances",
                         get_query_parameters, raw: true )

  end

  def show
    inst = LinkedData::Client::HTTP
      .get("/ontologies/#{params[:ontology]}/instances/#{CGI.escape(params[:instance])}",
           get_query_parameters, raw: true)

    render json: JSON.parse(inst)
  end

  private
  # json render + adding next and prev pages links
  def custom_render(instances)
    instances = JSON.parse(instances)
    if (instances.respond_to? :links) && (!instances.respond_to? :errors)
      instances.links = {
        nextPage: get_page_link(instances.nextPage),
        prevPage: get_page_link(instances.prevPage)
      }
    end

    render json: instances
  end

  def get_page_link(page_number)
    return nil if page_number.nil?

    if request.query_parameters.has_key?(:page)
      request.original_url.gsub(/page=\d+/, "page=#{page_number}")
    elsif request.query_parameters.empty?
      request.original_url + "?" + "page=#{page_number}"
    else
      request.original_url + "&" + "page=#{page_number}"
    end
  end

  def get_query_parameters
    params = request.query_parameters.slice(:include, :display, :page, :pagesize) || {}
    params[:include] = 'all' unless params.has_key? :include
    params
  end
end
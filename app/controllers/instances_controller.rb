class InstancesController < ApplicationController
  include InstancesHelper
  def index_by_ontology
    custom_render get_instances_by_ontology_json(params[:ontology], get_query_parameters)
  end

  def index_by_class
    custom_render get_instances_by_class_json(params[:ontology], params[:class], get_query_parameters)
  end

  def show
    inst = get_instance_details_json(params[:ontology], params[:instance], get_query_parameters)

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
    request.query_parameters.slice(:include, :display, :page, :pagesize, :search , :sortby , :order) || {}
  end
end
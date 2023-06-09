class Admin::CategoriesController < ApplicationController

  layout :determine_layout
  before_action :unescape_id, only: [:edit, :show, :update, :destroy]
  before_action :authorize_admin

  CATEGORIES_URL = "#{LinkedData::Client.settings.rest_url}/categories"

  def index
    response = _categories
    render :json => response
  end

  def new
    @category = LinkedData::Client::Models::Category.new

    respond_to do |format|
      format.html { render "new", :layout => false }
    end
  end

  def edit
    @category = LinkedData::Client::Models::Category.find_by_acronym(params[:id], include:'name,acronym,created,description,parentCategory,ontologies' ).first
    @ontologies_category = LinkedData::Client::Models::Ontology.all.map {|o|[o.acronym, o.id] }
    @id = "category_ontologies"
    @name = "category[ontologies]"
    @values = @ontologies_category
    @selected = @category.ontologies
    @multiple = true

    respond_to do |format|
      format.html { render "edit", :layout => false }
    end
  end

  def create
    response = { errors: '', success: '' }
    start = Time.now
    begin
      category = LinkedData::Client::Models::Category.new(values: category_params)
      category_saved = category.save
      if response_error?(category_saved)
        response[:errors] = response_errors(category_saved)
      else
        response[:success] = "category successfully created in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem creating the category  - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :created : :internal_server_error)

  end

  def update
    response = { errors: '', success: ''}
    start = Time.now
    begin
      category = LinkedData::Client::Models::Category.find_by_acronym(params[:id], include:'name,acronym,created,description,parentCategory,ontologies' ).first
      add_ontologies_to_category(category_params[:ontologies],category)
      delete_ontologies_from_category(category_params[:ontologies],category.ontologies,category)
      category.update_from_params(category_params)
      category_update = category.update
      if response_error?(category_update)
        response[:errors] = response_errors(category_update)
      else
        response[:success] = "category successfully updated in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem updating the category - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :ok : :internal_server_error)
  end

  def destroy
    response = { errors: '', success: ''}
    start = Time.now
    begin
      category = LinkedData::Client::Models::Category.find_by_acronym(params[:id]).first
      error_response = category.delete

      if response_error?(error_response)
        response[:errors] = response_errors(error_response)
      else
        response[:success] = "category successfully deleted in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem deleting the category - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :ok : :internal_server_error)
  end

  private

  def unescape_id
    params[:id] = CGI.unescape(params[:id])
  end

  def category_params
    params.require(:category).permit(:acronym, :name, :description, :parentCategory, {ontologies:[]}).to_h
  end

  def _categories
    response = { categories: Hash.new, errors: '', success: '' }
    start = Time.now
    begin
      response[:categories] = JSON.parse(LinkedData::Client::HTTP.get(CATEGORIES_URL, { include: 'ontologies,acronym,name,created,description,parentCategory' }, raw: true))

      response[:success] = "categories successfully retrieved in  #{Time.now - start}s"
      LOG.add :debug, "Categories - retrieved #{response[:categories].length} groups in #{Time.now - start}s"
    rescue Exception => e
      response[:errors] = "Problem retrieving categories  - #{e.message}"
    end
    response
  end

  def add_ontologies_to_category(ontologies,hasDomain)
    ontologies.each do |ont|
      unless hasDomain.ontologies.include?(ont)
        ontology = LinkedData::Client::Models::Ontology.find(ont)
        ontology.hasDomain.push(hasDomain.id)
        ontology.update
      end
    end
  end

  def delete_ontologies_from_category(new_ontologies,old_ontologies,hasDomain)
    ontologies = old_ontologies - new_ontologies  
    ontologies.each do |ont|
      ontology = LinkedData::Client::Models::Ontology.find(ont)
      ontology.hasDomain.delete(hasDomain.id)
      ontology.update
    end
  end
end

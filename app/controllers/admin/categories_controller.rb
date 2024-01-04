class Admin::CategoriesController < ApplicationController
  include SubmissionUpdater, TurboHelper


  layout :determine_layout
  before_action :unescape_id, only: [:edit, :show, :update, :destroy]
  before_action :authorize_admin

  CATEGORIES_URL = "#{LinkedData::Client.settings.rest_url}/categories"
  ATTRIBUTE_TO_INCLUDE = 'name,acronym,created,description,parentCategory,ontologies'

  def index
    @categories = _categories
  end

  def new
    @category = LinkedData::Client::Models::Category.new

    respond_to do |format|
      format.html { render "new", :layout => false }
    end
  end

  def edit
    @category = _category
    @acronyms = @category.ontologies.map { |url| url.match(/\/([^\/]+)$/)[1] }
    @ontologies_category = LinkedData::Client::Models::Ontology.all(include: 'acronym').map {|o|[o.acronym, o.id] }
    respond_to do |format|
      format.html { render "edit", :layout => false }
    end
  end

  def create
    response = { errors: nil, success: '' }
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

    if response[:errors]
      render_turbo_stream alert_error(id: 'category') { response[:errors] }
    else
      success_message = 'New Category added successfully'
      streams = [alert_success(id: 'category') { success_message }]

      streams << prepend('admin_categories_table_body', partial: 'admin/categories/category', locals: { category: category_saved })

      render_turbo_stream(*streams)
    end

  end

  def update
    response = { errors: nil, success: ''}
    start = Time.now
    begin
      category = _category
      add_ontologies_to_object(category_params[:ontologies],category) if (category_params[:ontologies].present? && category_params[:ontologies].size > 0 && category_params[:ontologies].first != '')
      delete_ontologies_from_object(category_params[:ontologies], category.ontologies,category)
      category.update_from_params(category_params)
      category.ontologies = Array(category_params[:ontologies])
      category_updated = category.update
      if response_error?(category_updated)
        response[:errors] = response_errors(category_updated)
      else
        response[:success] = "category successfully updated in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem updating the category - #{e.message}"
    end

    if response[:errors]
      render_turbo_stream(alert_error(id: 'category') { response[:errors] })
    else
      streams = [alert_success(id: 'category') { response[:success] },
                 replace(category.id.split('/').last, partial: 'admin/categories/category', locals: { category: category })
      ]
      render_turbo_stream(*streams)
    end

  end

  def destroy
    response = { errors: nil, success: ''}
    start = Time.now
    begin
      category = _category
      error_response = category.delete

      if response_error?(error_response)
        response[:errors] = response_errors(error_response)
      else
        response[:success] = "category successfully deleted in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem deleting the category - #{e.message}"
    end
    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render turbo_stream: [
            alert(type: 'success') { response[:success] },
            turbo_stream.remove(params[:id])
          ]
        end
      end
    end
  end
  private

  def unescape_id
    params[:id] = CGI.unescape(params[:id])
  end

  def category_params
    params.require(:category).permit(:acronym, :name, :description, :parentCategory, {ontologies:[]}).to_h
  end

  def _categories
    LinkedData::Client::HTTP.get(CATEGORIES_URL, { include: ATTRIBUTE_TO_INCLUDE })
  end

  def _category(id = params[:id])
    LinkedData::Client::HTTP.get(CATEGORIES_URL+ "/#{id.split('/').last}", { include: ATTRIBUTE_TO_INCLUDE })
  end
end

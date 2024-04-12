class Admin::SearchController < ApplicationController
  include TurboHelper
  layout :determine_layout
  before_action :authorize_admin

  SEARCH_URL = "#{LinkedData::Client.settings.rest_url}/admin/search"

  def index
    json = LinkedData::Client::HTTP.get("#{SEARCH_URL}/collections")
    @collections = json.collections
  end

  def index_batch
    response = {}
    model = params[:model_name]

    if model.blank?
      render_turbo_stream(alert(type: 'danger') { 'No model selected' })
      return
    end

    begin
      response[:success] = LinkedData::Client::HTTP.post("#{SEARCH_URL}/index_batch/#{model}", {})
    rescue StandardError => e
      response[:errors] = e
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { response[:success] }
        end
      end
    end
  end

  def init_schema
    response = {}
    collection = params[:collection]

    if collection.blank?
      render_turbo_stream(alert(type: 'danger') { 'No collection selected' })
      return
    end

    begin
      response[:success] = LinkedData::Client::HTTP.post("#{SEARCH_URL}/collections/#{collection}/schema/init", {})
    rescue StandardError => e
      response[:errors] = e
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { "Collection #{collection} schema initialized" }
        end
      end
    end
  end

  def show
    json = LinkedData::Client::HTTP.get("#{SEARCH_URL}/collections/#{params[:collection]}/schema", {}, raw: true)
    @collection = JSON.parse(json.to_s)

    @fields = @collection["fields"] + @collection["dynamicFields"] + @collection["copyFields"]
    render 'show', layout: false
  end

  def search
    query = params[:query] || '*'
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 10).to_i
    start = (page - 1) * page_size

    json = LinkedData::Client::HTTP.post("#{SEARCH_URL}/collections/#{params[:collection]}/search",
                                         { q: query, start: start, rows: page_size },
                                         raw: true)
    response = JSON.parse(json.to_s)
    @count = response["response"]["numFound"]
    @docs = response["response"]["docs"]

    render 'search', layout: false
  end

end

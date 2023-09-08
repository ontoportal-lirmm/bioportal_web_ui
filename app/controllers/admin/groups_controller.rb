class Admin::GroupsController < ApplicationController
  include SubmissionUpdater

  layout :determine_layout
  before_action :unescape_id, only: [:edit, :show, :update, :destroy]
  before_action :authorize_admin

  GROUPS_URL = "#{LinkedData::Client.settings.rest_url}/groups"

  def index
    response = _groups
    render :json => response
  end

  def new
    @group = LinkedData::Client::Models::Group.new

    respond_to do |format|
      format.html { render "new", :layout => false }
    end
  end

  def edit
    @group = LinkedData::Client::Models::Group.find_by_acronym(params[:id]).first
    @acronyms = @group.ontologies.map { |url| url.match(/\/([^\/]+)$/)[1] }
    @ontologies_group = LinkedData::Client::Models::Ontology.all(include: 'acronym').map {|o|[o.acronym, o.id] }
    respond_to do |format|
      format.html { render "edit", :layout => false }
    end
  end

  def create
    response = { errors: '', success: '' }
    start = Time.now
    begin
      group = LinkedData::Client::Models::Group.new(values: group_params)
      group_saved = group.save
      if response_error?(group_saved)
        response[:errors] = response_errors(group_saved)
      else
        response[:success] = "group successfully created in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem creating the group  - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :created : :internal_server_error)

  end

  def update
    response = { errors: '', success: ''}
    start = Time.now
    begin
      group = LinkedData::Client::Models::Group.find_by_acronym(params[:id]).first
      add_ontologies_to_object(group_params[:ontologies],group) if (group_params[:ontologies].present? && group_params[:ontologies].size > 0 && group_params[:ontologies].first != '')
      delete_ontologies_from_object(group_params[:ontologies],group.ontologies,group)
      group.update_from_params(group_params)
      group_updated = group.update
      if response_error?(group_updated)
        response[:errors] = response_errors(group_updated)
      else
        response[:success] = "group successfully updated in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem updating the group - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :ok : :internal_server_error)
  end

  def destroy
    response = { errors: '', success: ''}
    start = Time.now
    begin
      group = LinkedData::Client::Models::Group.find_by_acronym(params[:id]).first
      error_response = group.delete

      if response_error?(error_response)
        response[:errors] = response_errors(error_response)
      else
        response[:success] = "group successfully deleted in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem deleting the group - #{e.message}"
    end
    render json: response, status: (response[:errors] == '' ? :ok : :internal_server_error)
  end

  private

  def unescape_id
    params[:id] = CGI.unescape(params[:id])
  end

  def group_params
    params.require(:group).permit(:acronym, :name, :description, {ontologies:[]}).to_h()
  end

  def _groups
    response = { groups: Hash.new, errors: '', success: '' }
    start = Time.now
    begin
      response[:groups] = JSON.parse(LinkedData::Client::HTTP.get(GROUPS_URL, { include: 'all' }, raw: true))

      response[:success] = "groups successfully retrieved in  #{Time.now - start}s"
      LOG.add :debug, "Groups - retrieved #{response[:groups].length} groups in #{Time.now - start}s"
    rescue Exception => e
      response[:errors] = "Problem retrieving groups  - #{e.message}"
    end
    response
  end
end

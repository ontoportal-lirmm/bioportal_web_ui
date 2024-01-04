class Admin::GroupsController < ApplicationController
  include SubmissionUpdater, TurboHelper, AdminHelper

  layout :determine_layout
  before_action :unescape_id, only: [:edit, :show, :update, :destroy]
  before_action :authorize_admin

  GROUPS_URL = "#{LinkedData::Client.settings.rest_url}/groups"
  GROUPS_SYNCHRONIZE_URL = "#{LinkedData::Client.settings.rest_url}/slices/synchronize_groups"


  def index
    @groups = _groups
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
    response = { errors: nil, success: '' }
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

    if response[:errors]
      render_turbo_stream alert_error(id: 'group') { response[:errors] }
    else
      success_message = 'New Group added successfully'
      streams = [alert_success(id: 'group') { success_message }]

      streams << prepend('admin_groups_table_body', partial: 'admin/groups/group', locals: { group: group_saved })

      render_turbo_stream(*streams)
    end

  end

  def update
    response = { errors: nil, success: ''}
    start = Time.now
    begin
      group = LinkedData::Client::Models::Group.find_by_acronym(params[:id]).first
      add_ontologies_to_object(group_params[:ontologies],group) if (group_params[:ontologies].present? && group_params[:ontologies].size > 0 && group_params[:ontologies].first != '')
      delete_ontologies_from_object(group_params[:ontologies],group.ontologies,group)
      group.update_from_params(group_params)
      group.ontologies = Array(group_params[:ontologies])
      group_updated = group.update
      if response_error?(group_updated)
        response[:errors] = response_errors(group_updated)
      else
        response[:success] = "group successfully updated in  #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem updating the group - #{e.message}"
    end

    if response[:errors]
      render_turbo_stream(alert_error(id: 'group') { response[:errors] })
    else

      streams = [alert_success(id: 'group') { response[:success] },
                 replace(group.id.split('/').last, partial: 'admin/groups/group', locals: { group: group })
      ]
      render_turbo_stream(*streams)
    end

  end

  def destroy
    response = { errors: nil, success: ''}
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

  def synchronize_groups
    response = {}

    begin
      response_raw = LinkedData::Client::HTTP.get(GROUPS_SYNCHRONIZE_URL, params, raw: true)

      response_json = JSON.parse(response_raw, symbolize_names: true)

      if !response_json.is_a?(Array) && response_json[:errors]
        _process_errors(response_json[:errors], response, true)
      else
        response[:success] = "Synchronization of groups started successfully"
      end
    rescue JSON::ParserError => e
      response[:errors] = "Error parsing JSON response - #{e.class}: #{e.message}"
    rescue Exception => e
      response[:errors] = "Problem synchronizing groups - #{e.class}: #{e.message}"
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


  private

  def unescape_id
    params[:id] = CGI.unescape(params[:id])
  end

  def group_params
    params.require(:group).permit(:acronym, :name, :description, {ontologies:[]}).to_h()
  end

  def _groups
    LinkedData::Client::HTTP.get(GROUPS_URL, { include: 'all' })
  end
end

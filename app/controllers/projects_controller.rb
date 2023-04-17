class ProjectsController < ApplicationController
  # GET /projects
  # GET /projects.xml

  layout :determine_layout

  def index
    @projects = LinkedData::Client::Models::Project.all
    @projects.reject! { |p| p.name.nil? }
    @projects.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    @ontologies = LinkedData::Client::Models::Ontology.all(include_views: true)
    @ontologies_hash = Hash[@ontologies.map {|ont| [ont.id, ont]}]
    if request.xhr?
      render action: "index", layout: false
    else
      render action: "index"
    end
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    projects = LinkedData::Client::Models::Project.find_by_acronym(params[:id])
    if projects.nil? || projects.empty?
      flash[:notice] = flash_error("Project not found: #{params[:id]}")
      redirect_to projects_path
      return
    end
    
    @project = projects.first
    @ontologies_used = []
    onts_used = @project.ontologyUsed
    onts_used.each do |ont_used|
      ont = LinkedData::Client::Models::Ontology.find(ont_used)
      unless ont.nil?
        @ontologies_used << Hash["name", ont.name, "acronym", ont.acronym]
      end
    end
    @ontologies_used.sort_by!{ |o| o["name"].downcase }
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      @project = LinkedData::Client::Models::Project.new
      @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
      @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    end
  end

  # GET /projects/1/edit
  def edit
    projects = LinkedData::Client::Models::Project.find_by_acronym(params[:id])
    if projects.nil? || projects.empty?
      flash[:notice] = flash_error("Project not found: #{params[:id]}")
      redirect_to projects_path
      return
    end
    @project = projects.first
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    @usedOntologies = @project.ontologyUsed || []
    @ontologies = LinkedData::Client::Models::Ontology.all
  end

  # POST /projects
  # POST /projects.xml
  def create
    if params['commit'] == 'Cancel'
      redirect_to projects_path
      return
    end

    @project = LinkedData::Client::Models::Project.new(values: project_params)
    @project_saved = @project.save
    
    # Project successfully created.
    if response_success?(@project_saved)
      flash[:notice] = 'Project successfully created'
      redirect_to project_path(@project.acronym)
      return
    end

    # Errors creating project.
    if @project_saved.status == 409
      error = OpenStruct.new existence: "Project with acronym #{params[:project][:acronym]} already exists.  Please enter a unique acronym."
      @errors = Hash[:error, OpenStruct.new(acronym: error)]
    else
      @errors = response_errors(@project_saved)
    end

    @project = LinkedData::Client::Models::Project.new(values: project_params)
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    render action: "new"
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    if params['commit'] == 'Cancel'
      redirect_to projects_path
      return
    end
    projects = LinkedData::Client::Models::Project.find_by_acronym(params[:id])
    if projects.nil? || projects.empty?
      flash[:notice] = flash_error("Project not found: #{params[:id]}")
      redirect_to projects_path
      return
    end
    @project = projects.first
    @project.update_from_params(project_params)
    @user_select_list = LinkedData::Client::Models::User.all.map {|u| [u.username, u.id]}
    @user_select_list.sort! {|a,b| a[1].downcase <=> b[1].downcase}
    @usedOntologies = @project.ontologyUsed || []
    @ontologies = LinkedData::Client::Models::Ontology.all
    error_response = @project.update
    if response_error?(error_response)
      @errors = response_errors(error_response)
      render :edit
    else
      flash[:notice] = 'Project successfully updated'
      redirect_to project_path(@project.acronym)
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    projects = LinkedData::Client::Models::Project.find_by_acronym(params[:id])
    if projects.nil? || projects.empty?
      flash[:notice] = flash_error("Project not found: #{params[:id]}")
      redirect_to projects_path
      return
    end
    @project = projects.first
    error_response = @project.delete
    if response_error?(error_response)
      @errors = response_errors(error_response)
      flash[:notice] = "Project delete failed: #{@errors}"
      respond_to do |format|
        format.html { redirect_to projects_path }
        format.xml  { head :internal_server_error }
      end
    else
      flash[:notice] = 'Project successfully deleted'
      respond_to do |format|
        format.html { redirect_to projects_path }
        format.xml  { head :ok }
      end
    end

  end

  private

  def project_params
    p = params.require(:project).permit(:name, :acronym, :institution, :contacts, { creator:[] }, :homePage,
                                        :description, { ontologyUsed:[] })
    p[:creator].reject!(&:blank?)
    p[:ontologyUsed].reject!(&:blank?)
    p.to_h
  end

  def flash_error(msg)
    html = ''.html_safe
    html << '<span style=color:red;>'.html_safe
    html << msg
    html << '</span>'.html_safe
  end

end

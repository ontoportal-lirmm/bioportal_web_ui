class UsersController < ApplicationController
  
  before_action :unescape_id, only: [:edit, :show, :update]
  before_action :verify_owner, only: [:edit, :show]
  before_action :authorize_admin, only: [:index]

  layout :determine_layout

  # GET /users
  # GET /users.xml
  def index
    @users = LinkedData::Client::Models::User.all
    respond_to do |format|
      format.html
      format.xml { render xml: @users.to_xml }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = if session[:user].admin? && params.has_key?(:id)
              LinkedData::Client::Models::User.find_by_username(params[:id]).first
            else
              LinkedData::Client::Models::User.find(session[:user].id)
            end

    @all_ontologies = LinkedData::Client::Models::Ontology.all(ignore_custom_ontologies: true)

    logger.info 'user show'
    logger.info @user.bring_remaining
    logger.info @user
    @user_ontologies = @user.customOntology

    ## Copied from home controller , account action
    onts = LinkedData::Client::Models::Ontology.all;
    @admin_ontologies = onts.select {|o| o.administeredBy.include? @user.id }

    projects = LinkedData::Client::Models::Project.all;
    @user_projects = projects.select {|p| p.creator.include? @user.id }
  end

  # GET /users/new
  def new
    @user = LinkedData::Client::Models::User.new
  end

  # GET /users/1;edit
  def edit
    @user = LinkedData::Client::Models::User.find(params[:id])
    @user ||= LinkedData::Client::Models::User.find_by_username(params[:id]).first

    if (params[:password].eql?("true"))
      @user.validate_password = true
    end
  end

  # POST /users
  # POST /users.xml
  def create
    @errors = validate(user_params)
    @user = LinkedData::Client::Models::User.new(values: user_params)

    if @errors.size < 1
      @user_saved = @user.save
      if response_error?(@user_saved)
        @errors = response_errors(@user_saved)
        # @errors = {acronym: "Username already exists, please use another"} if @user_saved.status == 409
        render action: "new"
      else
        # Attempt to register user to list
        if params[:user][:register_mail_list]
          SubscribeMailer.register_for_announce_list(@user.email,@user.firstName,@user.lastName).deliver rescue nil
        end

        flash[:notice] = 'Account was successfully created'
        session[:user] = LinkedData::Client::Models::User.authenticate(@user.username, @user.password)
        redirect_to_browse
      end
    else
      render action: "new"
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = LinkedData::Client::Models::User.find(params[:id])
    @user = LinkedData::Client::Models::User.find_by_username(params[:id]).first if @user.nil?
    @errors = validate_update(user_params)
    if @errors.size < 1

      if params[:user][:password]
        error_response = @user.update(values: { password: params[:user][:password] })
      else
        user_roles = @user.role

        if @user.admin? != (params[:user][:admin].to_i == 1)
          user_roles = update_role(@user)
        end

        @user.update_from_params(user_params.merge!(role: user_roles))
        error_response = @user.update
      end

      if response_error?(error_response)
        @errors = response_errors(error_response)
        # @errors = {acronym: "Username already exists, please use another"} if error_response.status == 409
        render action: "edit"
      else
        flash[:notice] = 'Account was successfully updated'

        if session[:user].username == @user.username
          session[:user].update_from_params(user_params)
        end
        redirect_to user_path(@user.username)
      end
    else
      render action: "edit"
    end
  end

  # DELETE /users/1
  def destroy
    response = {errors: '', success: ''}
    @user = LinkedData::Client::Models::User.find(params[:id])
    @user = LinkedData::Client::Models::User.find_by_username(params[:id]).first if @user.nil?
    if(session[:user].admin?)
      @user.delete
      response[:success] << 'User deleted successfully '

    else
      response[:errors] << 'Not permitted '
    end

    render json: response
  end

  def custom_ontologies
    @user = LinkedData::Client::Models::User.find(params[:id])
    @user = LinkedData::Client::Models::User.find_by_username(params[:id]).first if @user.nil?

    custom_ontologies = params[:ontology] ? params[:ontology][:ontologyId] : []
    custom_ontologies.reject!(&:blank?)
    @user.update_from_params(customOntology: custom_ontologies)
    error_response = @user.update

    if error_response
      flash[:notice] = 'Error saving Custom Ontologies, please try again'
    else
      updated_user = LinkedData::Client::Models::User.find(@user.id)
      session[:user].update_from_params(customOntology: updated_user.customOntology)
      flash[:notice] = if updated_user.customOntology.empty?
                         'Custom Ontologies were cleared'
                       else
                         'Custom Ontologies were saved'
                       end
    end
    redirect_to user_path(@user.username)
  end

  
  def subscribe
    @user = LinkedData::Client::Models::User.find_by_username(params[:username]).first
    deliver "subscribe", SubscribeMailer.register_for_announce_list(@user.email,@user.firstName,@user.lastName)
  end

  def un_subscribe
    @email = params[:email] 
    deliver "un_subscribe", SubscribeMailer.unregister_for_announce_list(@email)
  end

  
  private

  def deliver(action,job)
    begin
      job.deliver
      flash[:success] = "You have #{action} successfully"
    rescue => exception
      flash[:error] = "Something went wrong ..."
    end
    redirect_to '/account'
  end

  def user_params
    p = params.require(:user).permit(:firstName, :lastName, :username, :email, :email_confirmation, :password,
                                     :password_confirmation, :register_mail_list, :admin)
    p.to_h
  end

  def unescape_id
    params[:id] = CGI.unescape(params[:id])
  end

  def verify_owner
    return if current_user_admin?
    if session[:user].nil? || (!session[:user].id.eql?(params[:id]) && !session[:user].username.eql?(params[:id]))
      redirect_to controller: 'login', action: 'index', redirect: "/accounts/#{params[:id]}"
    end
  end

  def get_ontology_list(ont_hash)
    return "" if ont_hash.nil?
    ontologies = []
    ont_hash.each do |ont, checked|
      ontologies << ont if checked.to_i == 1
    end
    ontologies.join(";")
  end

  def validate(params)
    errors = []
    if params[:email].nil? || params[:email].length < 1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i)
      errors << "Please enter an email address"
    end
    if !params[:email].eql?(params[:email_confirmation])
      errors << "Your Email and Email Confirmation do not match"
    end
    if params[:password].nil? || params[:password].length < 1
      errors << "Please enter a password"
    end
    if !params[:password].eql?(params[:password_confirmation])
      errors << "Your Password and Password Confirmation do not match"
    end
    if using_captcha?
      if !verify_recaptcha
        errors << "Please fill in the proper text from the supplied image"
      end
    end

    return errors
  end

  def validate_update(params)
    errors = []
    if params[:email].nil? || params[:email].length < 1 || !params[:email].match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      errors << "Please enter an email address"
    end
    if !params[:password].eql?(params[:password_confirmation])
      errors << "Your Password and Password Confirmation do not match"
    end

    return errors
  end

  def update_role(user)
    user_roles = user.role

    if session[:user].admin?
      user_roles = user_roles.dup
      if user.admin?
        user_roles.map!{ |role| role == "ADMINISTRATOR" ? "LIBRARIAN" : role}
      else
        user_roles.map!{ |role| role == "LIBRARIAN" ? "ADMINISTRATOR" : role}
      end
    end

    user_roles
  end

end

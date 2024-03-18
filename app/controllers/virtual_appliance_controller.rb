class VirtualApplianceController < ApplicationController
  layout 'ontology'
  before_action :require_login

  def index
    @user = session[:user]

    @virtual_appliance_user = VirtualApplianceUser.where(user_id: @user.id)

    @virtual_appliance_access = false
    if !@virtual_appliance_user.nil? && !@virtual_appliance_user.empty? || @user.admin?
      @virtual_appliance_access = true
    end

    @va_users = VirtualApplianceUser.order(:user_id)
  end

  def create
    user = LinkedData::Client::Models::User.find_by_username(params[:appliance_user][:user_id]).first

    if user.nil?
      flash[:error] = t('ontoportal_virtual_appliance.problem_adding_account', id: params[:appliance_user][:user_id]).html_safe
      redirect_to action: 'index' and return
    end

    @new_user = VirtualApplianceUser.where(user_id: user.id)
    if @new_user.nil? || @new_user.empty?
      @new_user = VirtualApplianceUser.new
      @new_user.user_id = user.id
      @new_user.save
    end

    redirect_to :action => 'index'
  end

  private

  def require_login
    return if session[:user]

    flash[:error] = t('ontoportal_virtual_appliance.require_login')
    redirect_to login_index_path(redirect: virtual_appliance_index_path)
  end
end

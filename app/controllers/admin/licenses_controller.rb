class Admin::LicensesController < ApplicationController

  def index
    @licenses = License.current_license
  end

  def new
    @license = License.new
  end

  def create
    @license = License.new(license_params)

    if @license.save
      render :create_success
    else
      render :new
    end
  end

  private

  def license_params
    params.require(:license).permit(:encrypted_key)
  end

end

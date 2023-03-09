class Admin::LicensesController < ApplicationController
  def index
    @licenses = License.current_license
    respond_to :js
  end

  def new
    @license = License.new
  end

  def create
    @license = License.new(license_params)

    respond_to do |format|
      if @license.save
        format.js { flash.now[:notice] = t(".success") }
      else
        format.js { render :new }
      end
    end
  end

  private

  def license_params
    params.require(:license).permit(:encrypted_key)
  end
end

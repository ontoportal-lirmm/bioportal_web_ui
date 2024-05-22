class ErrorsController < ApplicationController

  layout :determine_layout

  def not_found
    @referer_url = request.referer
    render status: 404
  end

  def internal_server_error
    @referer_url = request.referer
    render status: 500
  end

end

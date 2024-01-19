class CheckResolvabilityController < ApplicationController
  layout "tool"
  helper CheckResolvabilityHelper

  def index
    if params[:url]
      @url = params[:url]
      @results = helpers.check_resolvability_helper(@url)
    end
  end
end

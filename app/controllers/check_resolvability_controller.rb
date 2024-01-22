class CheckResolvabilityController < ApplicationController
  layout "tool"
  include TurboHelper

  def index
    if params[:url]
      @url = params[:url]
      @results = helpers.check_resolvability_helper(@url)
    end
  end

  def check_resolvability
    url = params[:url]
    container = "#{helpers.escape(params[:url])}_container"
    result = helpers.check_resolvability_helper(url)
    render_turbo_stream(replace(container) {
      render_to_string UrlResolvabilityComponent.new(resolvable: result[:result].eql?(1) || result[:result].eql?(2),
                                                     status: result[:status],
                                                     supported_formats: result[:allowed_format]), layout: false
    })
  end

end

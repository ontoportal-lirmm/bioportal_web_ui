require 'cgi'

# The redirect controller allows for routes-based redirects
# as we move old content to new URL locations.

class RedirectController < ApplicationController
  def index
    if params[:url] # We were provided with a url to redirect to
      params_string = ""
      # Trigger to switch the placeholders
      first_param = true
      # Loop through the given params, ignore ones we know about or are provided by default
      params.each do |param, value|
        next if ["url", "action", "controller"].include?(param)
        seperator = first_param ? "?" : "&"
        first_param = false
        params_string += seperator + param + "=" + escape(value)
      end
      # Redirect with params intact
      redirect_to params[:url] + params_string, :status=>:moved_permanently
      return
    else # Default redirect to the home page
      redirect_to "/", :status=>:moved_permanently
    end
  end
end

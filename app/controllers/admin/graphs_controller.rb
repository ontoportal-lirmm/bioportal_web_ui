require 'multi_json'

class Admin::GraphsController < ApplicationController

  include TurboHelper

  layout :determine_layout
  before_action :authorize_admin

  GRAPHS_URL = "#{LinkedData::Client.settings.rest_url}/admin/graphs".freeze

  def index
    @graphs = LinkedData::Client::HTTP.get(GRAPHS_URL.dup, { raw: true }, { raw: true })
    @graphs = MultiJson.load(@graphs)
  end

end

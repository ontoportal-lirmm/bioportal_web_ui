require 'multi_json'
class Admin::GraphsController < ApplicationController

  include TurboHelper

  layout :determine_layout
  before_action :authorize_admin

  GRAPHS_URL = "#{LinkedData::Client.settings.rest_url}/admin/graphs"

  def index
    @graphs = LinkedData::Client::HTTP.get("#{GRAPHS_URL}", { raw: true }, { raw: true })
    @graphs = MultiJson.load(@graphs)
  end

  def create

  end

  def destroy

  end
end

require 'multi_json'

class Admin::LogsController < ApplicationController

  include TurboHelper

  layout :determine_layout
  before_action :authorize_admin

  ALL_LOGS = "#{LinkedData::Client.settings.rest_url}/admin/latest_day_query_logs".freeze
  LATEST_LOGS = "#{LinkedData::Client.settings.rest_url}/admin/last_n_s_query_logs?seconds=10".freeze
  USERS_QUERY_COUNT = "#{LinkedData::Client.settings.rest_url}/admin/user_query_count".freeze
  def index
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 100).to_i
    @logs = LinkedData::Client::HTTP.get(ALL_LOGS.dup, { page: page, pagesize: page_size })
  end

end

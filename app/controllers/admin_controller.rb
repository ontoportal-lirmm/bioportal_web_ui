class AdminController < ApplicationController
  include TurboHelper, HomeHelper, SparqlHelper
  layout :determine_layout
  before_action :cache_setup

  ADMIN_URL = "#{LinkedData::Client.settings.rest_url}/admin/"
  ONTOLOGIES_URL = "#{ADMIN_URL}ontologies_report"
  USERS_URL = "#{LinkedData::Client.settings.rest_url}/users"
  ONTOLOGY_URL = lambda { |acronym| "#{ADMIN_URL}ontologies/#{acronym}" }
  PARSE_LOG_URL = lambda { |acronym| "#{ONTOLOGY_URL.call(acronym)}/log" }
  REPORT_NEVER_GENERATED = "NEVER GENERATED"

  def sparql_endpoint
    graph = params["named-graph-uri"]
    if !session[:user]&.admin? && !graph.blank?
      acronym = graph.split('/')[-3]
      @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
      render(inline: 'Query not permitted') && return  if @ontology.nil? || @ontology.errors
    end

    response = helpers.ontology_sparql_query(params[:query], graph)

    render inline:  response
  end

  def index
    @users = LinkedData::Client::Models::User.all
    @ontology_visits = ontology_visits_data
    @users_visits = user_visits_data
    @page_visits = page_visits_data
    @ontologies_problems_count = _ontologies_report[:ontologies]&.select{|a,v| v[:problem]}&.size || 0

    if session[:user].nil? || !session[:user].admin?
      redirect_to :controller => 'login', :action => 'index', :redirect => '/admin'
    else
      render action: "index"
    end
  end


  def update_check_enabled
    enabled = LinkedData::Client::HTTP.get("#{ADMIN_URL}update_check_enabled", {}, raw: false)

    if enabled
      response = {update_info: Hash.new, errors: nil, success: '', notices: ''}
      json = LinkedData::Client::HTTP.get("#{ADMIN_URL}update_info", params, raw: true)

      begin
        update_info = JSON.parse(json)

        if update_info["error"]
          response[:errors] = update_info["error"]
        else
          response[:update_info] = update_info
          response[:notices] = update_info["notes"] if update_info["notes"]
          response[:success] = "Update info successfully retrieved"
        end
      rescue Exception => e
        response[:errors] = "Problem retrieving update info - #{e.message}"
      end

      if response[:errors]
        render_turbo_stream alert(id: 'update_check_frame', type: 'danger') { response[:errors] }
      else
        output = []

        output << response[:update_info]["notes"]  if response[:update_info]["update_available"]

        output <<  "Current version: #{response[:update_info]['current_version']}"
        output <<  "Appliance ID: #{response[:update_info]['appliance_id']}"


        render_turbo_stream *output.map{|message|   alert(id: 'update_check_frame', type: 'info') {message} }


      end
    else
      render_turbo_stream alert(id: 'update_check_frame', type: 'info') { 'not enabled' }
    end
  end


  def parse_log
    @acronym = params["acronym"]
    @parse_log = LinkedData::Client::HTTP.get(PARSE_LOG_URL.call(params["acronym"]), {}, raw: false)
    ontologies_report = _ontologies_report
    ontology = ontologies_report[:ontologies][params["acronym"].to_sym]
    @log_file_path = ''

    if ontology
      full_log_file_path = ontology[:logFilePath]
      @log_file_path = /#{params["acronym"]}\/\d+\/[-a-zA-Z0-9_]+\.log$/.match(full_log_file_path)
    else
      @parse_log = "No record exists for ontology #{params["acronym"]}"
      @log_file_path = "None"
    end
    render action: "parse_log"
  end

  def clearcache
    response = {errors: nil, success: ''}

    if @cache.respond_to?(:flush_all)
      begin
        @cache.flush_all
        response[:success] = "UI cache successfully flushed"
      rescue Exception => e
        response[:errors] = "Problem flushing the UI cache - #{e.class}: #{e.message}"
      end
    else
      response[:errors] = "The UI cache does not respond to the 'flush_all' command"
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { response[:success] }
        end
      end
    end

  end

  def resetcache
    response = {errors: nil, success: ''}

    if @cache.respond_to?(:reset)
      begin
        @cache.reset
        response[:success] = "UI cache connection successfully reset"
      rescue Exception => e
        response[:errors] = "Problem resetting the UI cache connection - #{e.message}"
      end
    else
      response[:errors] = "The UI cache does not respond to the 'reset' command"
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { response[:success] }
        end
      end
    end
  end

  def clear_goo_cache
    response = {errors: nil, success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post("#{ADMIN_URL}clear_goo_cache", params, raw: true)
      response[:success] = "Goo cache successfully flushed"
    rescue Exception => e
      response[:errors] = "Problem flushing the Goo cache - #{e.class}: #{e.message}"
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { response[:success] }
        end
      end
    end

  end

  def clear_http_cache
    response = {errors: nil, success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post("#{ADMIN_URL}clear_http_cache", params, raw: true)
      response[:success] = "HTTP cache successfully flushed"
    rescue Exception => e
      response[:errors] = "Problem flushing the HTTP cache - #{e.class}: #{e.message}"
    end

    respond_to do |format|
      format.turbo_stream do
        if response[:errors]
          render_turbo_stream alert(type: 'danger') { response[:errors].to_s }
        else
          render_turbo_stream alert(type: 'success') { response[:success] }
        end
      end
    end
  end

  def ontologies_report
    response = _ontologies_report
    render :json => response
  end

  def refresh_ontologies_report
    response = {errors: '', success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post(ONTOLOGIES_URL, params, raw: true)
      response_json = JSON.parse(response_raw, :symbolize_names => true)

      if response_json[:errors]
        _process_errors(response_json[:errors], response, true)
      else
        response = response_json

        if params["ontologies"].nil? || params["ontologies"].empty?
          response[:success] = "Refresh of ontologies report started successfully";
        else
          ontologies = params["ontologies"].split(",").map {|o| o.strip}
          response[:success] = "Refresh of report for ontologies: #{ontologies.join(", ")} started successfully";
        end
      end
    rescue Exception => e
      response[:errors] = "Problem refreshing report - #{e.class}: #{e.message}"
      # puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}"
    end
    render :json => response
  end


  def process_ontologies
    _process_ontologies('enqued for processing', 'processing', :_process_ontology)
  end

  def delete_ontologies
    _process_ontologies('and all its artifacts deleted', 'deleting', :_delete_ontology)
  end

  def delete_submission
    response = { errors: '', success: '' }
    submission_id = params["id"]
    begin
      ont = params["acronym"]
      ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ont).first

      if ontology
        submission = ontology.explore.submissions({ display: 'submissionId' }, submission_id)

        if submission
          error_response = submission.delete
          if response_error?(error_response)
            errors = response_errors(error_response)
            _process_errors(errors, response, true)
          else
            response[:success] << "Submission #{params["id"]} for ontology #{ont} was deleted successfully"
          end
        else
          response[:errors] << "Submission #{params["id"]} for ontology #{ont} was not found in the system"
        end
      else
        response[:errors] << "Ontology #{ont} was not found in the system"
      end
    rescue Exception => e
      response[:errors] << "Problem deleting submission #{params["id"]} for ontology #{ont} - #{e.class}: #{e.message}"
    end

    if params[:turbo_stream]
      if response[:errors].empty?
        render_turbo_stream( alert_success { response[:success] }, remove('submission_' + submission_id.to_s))

      else
        render_turbo_stream alert_error { response[:errors] }
      end
    else
      render :json => response
    end

  end


  private

  def cache_setup
    @cache = Rails.cache.instance_variable_get("@data")
  end

  def _ontologies_report
    response = {ontologies: Hash.new, report_date_generated: REPORT_NEVER_GENERATED, errors: '', success: ''}
    start = Time.now

    begin
      ontologies_data = LinkedData::Client::HTTP.get(ONTOLOGIES_URL, {}, raw: true)
      ontologies_data_parsed = JSON.parse(ontologies_data, :symbolize_names => true)

      if ontologies_data_parsed[:errors]
        _process_errors(ontologies_data_parsed[:errors], response, true)
      else
        response.merge!(ontologies_data_parsed)
        response[:success] = "Report successfully regenerated on #{ontologies_data_parsed[:report_date_generated]}"
        LOG.add :debug, "Ontologies Report - retrieved #{response[:ontologies].length} ontologies in #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem retrieving ontologies report - #{e.message}"
    end
    response
  end

  def _process_errors(errors, response, remove_trailing_comma=true)
    if errors.is_a?(Hash)
      errors.each do |_, v|
        if v.kind_of?(Array)
          response[:errors] << v.join(", ")
          response[:errors] << ", "
        else
          response[:errors] << "#{v}, "
        end
      end
    elsif errors.kind_of?(Array)
      errors.each {|err| response[:errors] << "#{err}, "}
    end
    response[:errors] = response[:errors][0...-2] if remove_trailing_comma
  end

  def _delete_ontology(ontology, params)
    error_response = ontology.delete
    error_response
  end

  def _process_ontology(ontology, params)
    LinkedData::Client::HTTP.put(ONTOLOGY_URL.call(ontology.acronym), params)
  end

  def _process_ontologies(success_keyword, error_keyword, process_proc)
    response = {errors: '', success: ''}

    if params["ontologies"].nil? || params["ontologies"].empty?
      response[:errors] = "No ontologies parameter passed. Syntax: ?ontologies=ONT1,ONT2,...,ONTN"
    else
      ontologies = params["ontologies"].split(",").map {|o| o.strip}

      ontologies.each do |ont|
        begin
          ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ont).first

          if ontology
            error_response = self.send(process_proc, ontology, params)
            if response_error?(error_response)
              errors = response_errors(error_response) # see application_controller::response_errors
              _process_errors(errors, response, false)
            else
              response[:success] << "Ontology #{ont} #{success_keyword} successfully, "
            end
          else
            response[:errors] << "Ontology #{ont} was not found in the system, "
          end
        rescue Exception => e
          response[:errors] << "Problem #{error_keyword} ontology #{ont} - #{e.class}: #{e.message}, "
        end
      end
      response[:success] = response[:success][0...-2] unless response[:success].empty?
      response[:errors] = response[:errors][0...-2] unless response[:errors].empty?
    end
    render :json => response
  end


  def user_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/users", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }

    return visits_data if analytics.empty?

    analytics.each do |year, year_data|
      year_data.each do |month, value|
        visits_data[:visits] << value
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    visits_data
  end

  def ontology_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/ontologies", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }
    @new_ontologies_count = []
    @ontologies_count = 0

    return visits_data if analytics.empty?

    aggregated_data = {}
    analytics.each do |acronym, years_data|
      current_year_count = 0
      previous_year_count  = 0
      years_data.each do |year, months_data|
        previous_year_count += current_year_count
        current_year_count = 0
        aggregated_data[year] ||= {}
        months_data.each do |month, value|
          if aggregated_data[year][month]
            aggregated_data[year][month] += value
          else
            aggregated_data[year][month] = value
          end
          current_year_count += value
        end
      end
      @ontologies_count += 1
      if previous_year_count.zero? && current_year_count.positive?
        @new_ontologies_count << [acronym]
      end
    end



    aggregated_data.each do |year, year_data|
      year_data.each do |month, value|
        visits_data[:visits] << value
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    visits_data
  end

  def page_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/page_visits", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }

    return visits_data if analytics.empty?
    analytics.each do |path, count|
      visits_data[:labels] << path
      visits_data[:visits] << count
    end
    visits_data
  end
end

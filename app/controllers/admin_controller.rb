require_relative '../utils/utils'
require_relative '../utils/datacite_srv'
class AdminController < ApplicationController
  include TurboHelper
  layout :determine_layout
  before_action :cache_setup

  ADMIN_URL = "#{LinkedData::Client.settings.rest_url}/admin/"
  ONTOLOGIES_URL = "#{ADMIN_URL}ontologies_report"
  USERS_URL = "#{LinkedData::Client.settings.rest_url}/users"
  ONTOLOGY_URL = lambda { |acronym| "#{ADMIN_URL}ontologies/#{acronym}" }
  PARSE_LOG_URL = lambda { |acronym| "#{ONTOLOGY_URL.call(acronym)}/log" }
  REPORT_NEVER_GENERATED = "NEVER GENERATED"
  ONTOLOGIES_LIST_URL = "#{LinkedData::Client.settings.rest_url}/ontologies/"
  DOI_REQUESTS_URL = "#{ADMIN_URL}doi_requests_list"
  SUB_DATACITE_METADATA_JSON_URL = lambda { |acronym, subId| "#{ONTOLOGIES_LIST_URL}#{acronym}/submissions/#{subId}/datacite_metadata_json" }

  def index
    @users = LinkedData::Client::Models::User.all
    if session[:user].nil? || !session[:user].admin?
      redirect_to :controller => 'login', :action => 'index', :redirect => '/admin'
    else
      render action: "index"
    end
  end

  def update_info
    response = {update_info: Hash.new, errors: '', success: '', notices: ''}
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
    render :json => response
  end

  def update_check_enabled
    enabled = LinkedData::Client::HTTP.get("#{ADMIN_URL}update_check_enabled", {}, raw: false)
    render :json => enabled
  end

  def submissions
    @submissions = nil
    @acronym = params["acronym"]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params["acronym"]).first
    begin
      submissions = @ontology.explore.submissions
      @submissions = submissions.sort {|a,b| b.submissionId <=> a.submissionId }
    rescue
      @submissions = []
    end
    render :partial => "layouts/ontology_report_submissions"
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
    response = {errors: '', success: ''}

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
    render :json => response
  end

  def resetcache
    response = {errors: '', success: ''}

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
    render :json => response
  end

  def clear_goo_cache
    response = {errors: '', success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post("#{ADMIN_URL}clear_goo_cache", params, raw: true)
      response[:success] = "Goo cache successfully flushed"
    rescue Exception => e
      response[:errors] = "Problem flushing the Goo cache - #{e.class}: #{e.message}"
    end
    render :json => response
  end

  def clear_http_cache
    response = {errors: '', success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post("#{ADMIN_URL}clear_http_cache", params, raw: true)
      response[:success] = "HTTP cache successfully flushed"
    rescue Exception => e
      response[:errors] = "Problem flushing the HTTP cache - #{e.class}: #{e.message}"
    end
    render :json => response
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

  def users
    response = _users
    render :json => response
  end
  
  def doi_requests_list
    response = _doi_requests_list
    render :json => response
  end

  def process_doi_requests
    response = { errors: '', success: '' }
    if params['actions'].nil? || params['actions'].empty?
      response[:errors] = "No operation 'actions' was specified in params for request processing"
      render :json => response
    else
      _process_doi_requests('processed', 'processing', params['actions'])
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

  def _users
    response = {users: Hash.new , errors: '', success: ''}
    start = Time.now
    begin
      response[:users] = JSON.parse(LinkedData::Client::HTTP.get(USERS_URL, {include: 'all'}, raw: true))

      response[:success] = "users successfully retrieved in  #{Time.now - start}s"
    LOG.add :debug, "Users - retrieved #{response[:users].length} users in #{Time.now - start}s"
    rescue Exception => e
      response[:errors] = "Problem retrieving users  - #{e.message}"
    end
    response
  end

  # DOI REQUESTES
  def _doi_requests_list
    response = { doi_requests: Hash.new, errors: '', success: '' }
    start = Time.now

    begin
      doi_requests_data = LinkedData::Client::HTTP.get(DOI_REQUESTS_URL, {}, raw: true)

      doi_requests_data_parsed = JSON.parse(doi_requests_data, symbolize_names: true)

      doi_requests_result = []
      doi_requests_data_parsed.each do |req|
        req_result = _create_doi_request_row_hash(req)
        doi_requests_result << req_result
      end

      response[:doi_requests] = doi_requests_result
      response[:success] = 'DOI requests list generated'
      LOG.add :debug, "DOI Requests List - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s"
    rescue StandardError => e
      response[:errors] = "Problem retrieving DOI Requests - #{e.message}"
    end
    response
  end

  #Create a Hash object of DOI Request that is compliant with admin panel
  def _create_doi_request_row_hash(req)
    req_result = {
      requestId: req[:requestId],
      requestType: req[:requestType],
      status: req[:status],
      requestedBy: req[:requestedBy],
      requestDate: req[:requestDate],
      processedBy: req[:processedBy],
      processingDate: req[:processingDate],
      message: req[:message],
      ontology: req[:submission].nil? || req[:submission][:ontology].nil? ? nil : req[:submission][:ontology][:acronym],
      submissionId: req[:submission].nil? ? nil : req[:submission][:submissionId],
      identifier: req[:submission].nil? ? nil : req[:submission][:identifier],
      identifierType: req[:submission].nil? ? nil : req[:submission][:identifierType],
      submissions_with_identifier: []
    }
    req_result
  end

  def _process_doi_requests(success_keyword, error_keyword, action)

    response = { errors: '', success: '' }

    if params['doi_requests'].nil? || params['doi_requests'].empty?
      response[:errors] = 'No doi_requests parameter passed. Syntax: ?doi_requests=req1,req2,...,reqN'
    else
      doi_requests = params['doi_requests'].split(',').map { |o| o.strip }
      doi_requests.each do |request_id|
        begin
          doi_request = LinkedData::Client::Models::IdentifierRequest.find_by_requestId(request_id).first
          if doi_request
            if doi_request.status.upcase == 'PENDING'
              #Get ontology submission information
              doi_req_submission = doi_request.explore.submission
              ont_submission_id = doi_req_submission.submissionId
              ontology_acronym = doi_req_submission.ontology.acronym
              ontology_id = doi_req_submission.ontology.id

              #sub_metadata_url = SUB_DATACITE_METADATA_JSON_URL.call(ontology_acronym, ont_submission_id)
              #open_struct_metadata = LinkedData::Client::HTTP.get(sub_metadata_url, {})

              #hash_metadata = Ecoportal::Utils.recursive_symbolize_keys(open_struct_metadata, true, true)
              error_response = nil
              case action
              when 'process'
                if doi_request.requestType == 'DOI_CREATE'
                  submission = _ontology_submission(ontology_id, ont_submission_id)
                  if submission
                    error_response = _satisfy_doi_creation_request(doi_request, hash_metadata, submission)
                  else
                    error_response = 'Ontology submission not found'
                  end

                elsif doi_request.requestType == 'DOI_UPDATE'
                  error_response = _satisfy_doi_update_request(doi_request, hash_metadata)
                end
              when 'reject'
                error_response = _change_request_status(doi_request, 'REJECTED') unless error_response
              else
                error_response = "action is different or nil: #{action}"
              end

              if error_response
                response[:errors] << "ERROR occurred in request #{request_id}:"
                errors = _datacite_response_errors(error_response)
                _process_errors(errors, response, false)
              else
                response[:success] << "Request #{request_id} #{success_keyword} successfully, "
              end
            else
              response[:errors] << "The request #{request_id} cannot be processed (STATUS = #{doi_request.status.upcase}), "
            end
          else
            response[:errors] << "Request #{request_id} was not found in the system, "
          end
        rescue Exception => e
          response[:errors] << "Problem #{error_keyword} Request #{request_id} - #{e.class}: #{e.message}, "
        end
      end
      response[:success] = response[:success][0...-2] unless response[:success].empty?
      response[:errors] = response[:errors][0...-2] unless response[:errors].empty?
    end
    render :json => response
  end

  def _datacite_response_errors(error_hash)
    errors = { error: 'There was an error, please try again' }
    return errors unless error_hash && error_hash.length > 0

    errors = {}
    error_hash.each do |error|
      p error
      p error.is_a?(Hash)
      p error.key?('title')
      if error.is_a?(Hash) && error.key?('title')
        errors[:error] = error['title']
      end
    end
    errors
  end

  def _ontology_submission(ontology_id, ont_submission_id)

    ontology = LinkedData::Client::Models::Ontology.get(ontology_id)
    submission = nil
    if ontology
      submissions = ontology.explore.submissions
      submission = submissions.select { |o| o.submissionId == ont_submission_id.to_i }.first
    end
    submission
  end

  def _satisfy_doi_creation_request(doi_request, hash_metadata, submission)
    hash_metadata[:prefix] = $DATACITE_DOI_PREFIX ### configured in bioportal_config_appliance.rb
    hash_metadata[:event] = 'publish' #"draft"

    datacite_hash = {
      data: {
        prefix: $DATACITE_DOI_PREFIX, ### configured in bioportal_config_appliance.rb
        type: 'dois',
        attributes: hash_metadata
      }
    }

    datacite_json = datacite_hash.to_json
    dc_response = Ecoportal::DataciteSrv.create_new_doi_from_datacite(datacite_json)

    #If there is an error, returns it
    return dc_response['errors'] if dc_response['errors'] && !dc_response['errors'].empty?

    #If the DOI isn't into the response, returns an error
    error = "The new DOI doesn't exist in the Datacite response: check the response: dc_response"
    return error unless dc_response['data']['id'] && !dc_response['data']['id'].empty?

    #UPDATE SUBMISSION WITH NEW DOI
    new_doi = dc_response['data']['id']
    new_values = {
      ontology: submission.ontology.id,
      identifier: new_doi,
      identifierType: 'DOI'
    }

    #retreive submission
    submission.update_from_params(new_values)

    error_submission = submission.update

    return error_submission unless error_submission.nil?

    #UPDATE THE STATUS OF DOI REQUEST TO "SATISFIED"
    doi_request.status = 'SATISFIED'
    doi_request.processedBy = session[:user].username
    doi_request.processingDate = DateTime.now.to_s
    error_doi_request = doi_request.update
    return error_doi_request unless error_doi_request.nil?

    nil
  end

  def _satisfy_doi_update_request(doi_request, hash_metadata)
    Ecoportal::DataciteSrv.update_doi_information_to_datacite(hash_metadata.to_json)
  end

  def _change_request_status(doi_request, new_status)
    doi_request.update(values: {status: new_status ,
                                processedBy: session[:user].id,
                                processingDate: DateTime.now.to_s
    })
  end

end

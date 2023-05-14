require 'uri'
require 'net/http'
require 'openssl'
require_relative '../utils/utils'
require_relative '../utils/datacite_srv'

class AdminController < ApplicationController
  include TurboHelper
  layout :determine_layout
  before_action :cache_setup

  DEBUG_BLACKLIST = [:"$,", :$ADDITIONAL_ONTOLOGY_DETAILS, :$rdebug_state,
                     :$PROGRAM_NAME, :$LOADED_FEATURES, :$KCODE, :$-i, :$rails_rake_task, :$$, :$gems_build_rake_task,
                     :$daemons_stop_proc, :$VERBOSE, :$DAEMONS_ARGV, :$daemons_sigterm,
                     :$DEBUG_BEFORE, :$stdout, :$-0, :$-l, :$-I, :$DEBUG, :$',
                     :$gems_rake_task, :$_, :$CODERAY_DEBUG, :$-F, :$", :$0, :$=, :$FILENAME, :$?,
                     :$!, :$rdebug_in_irb, :$-K, :$TESTING, :$fileutils_rb_have_lchmod,
                     :$EMAIL_EXCEPTIONS, :$binding, :$-v, :$>, :$SAFE, :$/,
                     :$fileutils_rb_have_lchown, :$-p, :$-W, :$:, :$__dbg_interface,
                     :$stderr, :$\, :$&, :$<, :$debug, :$;, :$~, :$-a,
                     :$DEBUG_RDOC, :$CGI_ENV, :$LOAD_PATH, :$-d, :$*, :$., :$-w, :$+,
                     :$@, :$`, :$stdin, :$1, :$2, :$3, :$4, :$5, :$6, :$7, :$8, :$9]
  ADMIN_URL = "#{LinkedData::Client.settings.rest_url}/admin/"
  ONTOLOGIES_URL = "#{ADMIN_URL}ontologies_report"
  USERS_URL = "#{LinkedData::Client.settings.rest_url}/users"
  ONTOLOGY_URL = lambda { |acronym| "#{ADMIN_URL}ontologies/#{acronym}" }
  PARSE_LOG_URL = lambda { |acronym| "#{ONTOLOGY_URL.call(acronym)}/log" }
  REPORT_NEVER_GENERATED = "NEVER GENERATED"

  ONTOLOGIES_LIST_URL = "#{LinkedData::Client.settings.rest_url}/ontologies/"
  DOI_REQUESTS_URL = "#{ADMIN_URL}doi_requests_list"
  DOI_REQUEST_URL = lambda { |requestId| "#{ADMIN_URL}doi_request/#{requestId}"}
  SUB_DATACITE_METADATA_JSON_URL = lambda { |acronym, subId| "#{ONTOLOGIES_LIST_URL}#{acronym}/submissions/#{subId}/datacite_metadata_json" }
  CREATE_DOI_URL = lambda { |requestId| "#{ADMIN_URL}doi_request/create_doi/#{requestId}" }
  UPDATE_DOI_URL = lambda { |requestId| "#{ADMIN_URL}doi_request/update_doi/#{requestId}" }

  def index
    @users = LinkedData::Client::Models::User.all

    if session[:user].nil? || !session[:user].admin?
      redirect_to :controller => 'login', :action => 'index', :redirect => '/admin'
    else
      json = LinkedData::Client::HTTP.get("#{ADMIN_URL}scheduled_jobs", raw: true)
      @scheduledJobs = JSON.parse(json, :symbolize_names => true)
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
  

  #=============================================================
  #                   DOI REQUESTs MANAGEMENT
  #=============================================================

  
  #ONTOLOGY_URL = lambda { |acronym| "#{ADMIN_URL}ontologies/#{acronym}" }

  def doi_requests_list
    response = _doi_requests_list
    render :json => response
  end

  def process_doi_requests
    response = {errors: '', success: ''}
    if params["actions"].nil? || params["actions"].empty?
      response[:errors] = "No operation 'actions' was specified in params for request processing"
      render :json => response
    else      
      _process_doi_requests('processed', 'processing', params["actions"])
    end
  end
  
  #=============================================================
  #                   PRIVATE METHODS
  #=============================================================

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
    response = {doi_requests: Hash.new, errors: '', success: ''}
    start = Time.now

    begin
      doi_requests_data = LinkedData::Client::HTTP.get(DOI_REQUESTS_URL, {}, raw: true)
      # LOGGER.debug("\n\n = = = = = = \n WEB_UI - ADMIN_CONTROLLER - _doi_requests_list: \n > doi_requests_data = #{doi_requests_data.inspect} ")
      
      doi_requests_data_parsed = JSON.parse(doi_requests_data, :symbolize_names => true)
      # LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _doi_requests_list: \n > doi_requests_data_parsed = #{doi_requests_data_parsed.inspect} ")

      doi_requests_result = []
      doi_requests_data_parsed.each do |req|
        # LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _doi_requests_list: \n > req = #{req.inspect} ")
        req_result = _createDoiRequestRowHash(req)
        doi_requests_result << req_result
        
      end

      response[:doi_requests] = doi_requests_result
      
      response[:success] = "DOI requests list generated"
      #LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _doi_requests_list - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s")
      LOG.add :debug, "DOI Requests List - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s"     
    rescue Exception => e
      response[:errors] = "Problem retrieving DOI Requests - #{e.message}"
      LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _doi_requests_list - EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}")
    end
    response
  end

  # #Return single Doi Request Row for admin panel
  # def _getDoiRequestRow()
  #   response = {doi_request: Hash.new, errors: '', success: ''}
  #   start = Time.now

  #   begin
  #     url = DOI_REQUEST_URL.call(doi_request.requestId) #<=== RICAVARE requestId
  #     doi_requests_data = LinkedData::Client::HTTP.get(url, {}, raw: true)
  #     LOGGER.debug("\n\n = = = = = = \n WEB_UI - ADMIN_CONTROLLER - _getDoiRequestRow: \n > doi_requests_data = #{doi_requests_data.inspect} ")
      
  #     doi_requests_data_parsed = JSON.parse(doi_requests_data, :symbolize_names => true)
  #     LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _getDoiRequestRow: \n > doi_requests_data_parsed = #{doi_requests_data_parsed.inspect} ")

  #     req_result = _createDoiRequestRowHash(doi_requests_data_parsed)
      
  #     response[:doi_request] = req_result      
  #     response[:success] = "DOI request retreived"

  #     LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _getDoiRequestRow - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s")
  #     LOG.add :debug, "DOI Requests List - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s"     
  #   rescue Exception => e
  #     response[:errors] = "Problem retrieving DOI Request - #{e.message}"
  #     LOGGER.debug("\n\n WEB_UI - ADMIN_CONTROLLER - _getDoiRequestRow - EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}")
  #   end
  #   response
  # end

  #Create a Hash object of DOI Request that is compliant with admin panel
  def _createDoiRequestRowHash(req)
    req_result = {
      requestId: req[:requestId],
      requestType: req[:requestType],
      status: req[:status],
      requestedBy: req[:requestedBy].nil? ? nil : req[:requestedBy].except(:id, :type, :links, :context, :created, :@id, :@type, :@links, :@context, :@created),
      requestDate: req[:requestDate],
      processedBy: req[:processedBy].nil? ? nil : req[:processedBy].except(:id, :type, :links, :context, :created, :@id, :@type, :@links, :@context, :@created),
      processingDate: req[:processingDate],
      message: req[:message],
      ontology: req[:submission].nil? || req[:submission][:ontology].nil? ? nil : req[:submission][:ontology][:acronym],
      submissionId: req[:submission].nil? ? nil : req[:submission][:submissionId],
      identifier: req[:submission].nil? ? nil : req[:submission][:identifier],
      identifierType: req[:submission].nil? ? nil : req[:submission][:identifierType],   
      submissions_with_identifier: []
    }
    return req_result
  end  
 
  def _process_doi_requests(success_keyword, error_keyword, action)
    
    response = {errors: '', success: ''}

    if params["doi_requests"].nil? || params["doi_requests"].empty?
      response[:errors] = "No doi_requests parameter passed. Syntax: ?doi_requests=req1,req2,...,reqN"
    else
      doi_requests = params["doi_requests"].split(",").map {|o| o.strip}
      #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests: doi_requests = #{doi_requests} ")
      doi_requests.each do |request_id|
        begin
          #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests: ACTION = #{action} - requestId #{request_id}")
          doi_request = LinkedData::Client::Models::IdentifierRequest.find_by_requestId(request_id).first
          if doi_request
            if doi_request.status.upcase == "PENDING"
              #Get ontology submission information
              doiReq_submission = doi_request.explore.submission
              #LOGGER.debug("(*) WEB_UI : admin_controller - _process_doi_requests - doiReq_submission = #{doiReq_submission.inspect}")
              ont_submission_id = doiReq_submission.submissionId
              ontology_acronym = doiReq_submission.ontology.acronym
              ontology_id = doiReq_submission.ontology.id

              submission = _getSubmission(ontology_id, ont_submission_id)
              #LOGGER.debug("(**) WEB_UI : admin_controller - _process_doi_requests - submission = #{submission.inspect}")
              
              sub_metadata_URL = SUB_DATACITE_METADATA_JSON_URL.call(ontology_acronym, ont_submission_id)
              #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - doi_request = #{doi_request.inspect} \n sub_metadata_URL = #{sub_metadata_URL} \n ontology_acronym= #{ontology_acronym} \n ont_submission_id=#{ont_submission_id}")
              openStructMetadata = LinkedData::Client::HTTP.get(sub_metadata_URL, {})
              #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - openStructMetadata = #{openStructMetadata.inspect}")
              #hashMetadata = struct_to_hash(openStructMetadata)
              hashMetadataInDataciteFormat = Ecoportal::Utils.recursive_symbolize_keys(openStructMetadata, true, true)
              #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - hashMetadataInDataciteFormat = #{hashMetadataInDataciteFormat}")
                          
              # sub_metadata_json = hashMetadata.to_json
              # LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - sub_metadata_json = #{sub_metadata_json}")
              #error_response = self.send(process_proc, ontology, params)
              error_response = nil
              case action
                when "process"
                  if doi_request.requestType == "DOI_CREATE"                    
                    #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - submission = #{submission}")
                    if submission
                      
                      error_response = _satisfyDoiCreationRequest(doi_request, hashMetadataInDataciteFormat, submission)
                      #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - AFTER CALL _satisfyDoiCreationRequest - error_response = #{error_response.inspect}")
                    else
                      error_response = "Ontology submission not found"
                    end

                  elsif doi_request.requestType == "DOI_UPDATE"
                    error_response = _satisfyDoiUpdateRequest(doi_request, hashMetadataInDataciteFormat)
                  end
                when "reject"
                  error_response = _changeRequestStatus(doi_request, "REJECTED") unless error_response
                else
                  error_response = "action is different or nil: #{action}"
                  #LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - action not valid = #{action}")
              end
              
              if error_response
                LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - error_response = #{error_response}")
                response[:errors] << "ERROR occurred in request #{request_id}:"
                errors = _datacite_response_errors(error_response) # see application_controller::response_errors
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
          LOGGER.debug("WEB_UI : admin_controller - _process_doi_requests - EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}")
          response[:errors] << "Problem #{error_keyword} Request #{request_id} - #{e.class}: #{e.message}, "
        end
      end
      response[:success] = response[:success][0...-2] unless response[:success].empty?
      response[:errors] = response[:errors][0...-2] unless response[:errors].empty?
    end
    render :json => response
  end
 
  

  private

  def _datacite_response_errors(error_hash)
    #LOGGER.debug("\n\n WEB_UI : admin_controller - _datacite_response_errors - error_hash = #{error_hash.inspect}")
    
    errors = {error: "There was an error, please try again"}
    return errors unless error_hash && error_hash.length > 0

    errors = {}
    error_hash.each do |error|
      p error
      p error.is_a?(Hash)
      p error.key?("title")
      if error.is_a?(Hash) && error.key?("title")
        errors[:error] = error["title"]
      end
    end
    errors
  end

  def _getSubmission(ontology_id, ont_submission_id)
    begin
      ontology = LinkedData::Client::Models::Ontology.get(ontology_id)
      submission = nil
      if(ontology)
        submissions = ontology.explore.submissions
        submission = submissions.select {|o| o.submissionId == ont_submission_id.to_i}.first
      end
      submission
    rescue Exception => e
      LOGGER.debug("WEB_UI : admin_controller - _getSubmission - error_response = #{error_response}")      
    end
  end

  def _satisfyDoiCreationRequest(doi_request, hashMetadata, submission)
    #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest")
    
    begin   

      hashMetadata[:prefix] = $DATACITE_DOI_PREFIX ### configured in bioportal_config_appliance.rb
      hashMetadata[:event] = "publish" #"draft"

      datacite_hash = {      
        data: {
          prefix: $DATACITE_DOI_PREFIX, ### configured in bioportal_config_appliance.rb
          type: "dois",
          attributes:hashMetadata
        }
      }
      
      
      datacite_json = datacite_hash.to_json
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest - datacite_json = #{datacite_json}")
      dc_response = Ecoportal::DataciteSrv.createNewDoiFromDatacite(datacite_json)
      
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest - dc_response = #{dc_response.inspect}")
      #If there is an error, returns it
      return dc_response["errors"] if dc_response["errors"] && !dc_response["errors"].empty?

      #If the DOI isn't into the response, returns an error
      error = "The new DOI doesn't exist in the Datacite response: check the response: dc_response"
      return error unless dc_response["data"]["id"] && !dc_response["data"]["id"].empty?

      #UPDATE SUBMISSION WITH NEW DOI
      new_DOI = dc_response["data"]["id"]
      newValues = {
        ontology: submission.ontology.id,
        identifier: new_DOI,
        identifierType: "DOI"
      }    
     
      #retreive submission 
      submission
      submission.update_from_params(newValues)
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest 1: submission to update: #{submission.inspect}")
      error_submission = submission.update
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest 2: error_submission = #{error_submission.inspect}") unless error_submission.nil?
      return error_submission unless error_submission.nil?
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest 3: submission UPDATED!!!")

      #UPDATE THE STATUS OF DOI REQUEST TO "SATISFIED"
      doi_request.status = "SATISFIED"
      doi_request.processedBy = session[:user].username
      doi_request.processingDate = DateTime.now.to_s
      error_doi_request = doi_request.update
      return error_doi_request unless error_doi_request.nil?
      #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest 4: request doi UPDATED!!! - error_doi_request:#{error_doi_request}")
      nil
    rescue => e
      LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiCreationRequest EXCEPTION : #{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end    
  end

  def _satisfyDoiUpdateRequest(doi_request, hashMetadata)
    #LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiUpdateRequest")
    
    begin
      error_response = Ecoportal::DataciteSrv.updateDoiInformationToDatacite(sub_metadata_json)
      error_response
    rescue => e
      LOGGER.debug("WEB_UI - admin_controller - _satisfyDoiUpdateRequest EXCEPTION : #{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end    
  end

  def _changeRequestStatus(doi_request, new_status)
    #LOGGER.debug("WEB_UI - admin_controller - _changeRequestStatus")    
    begin
      doi_request.status = new_status
      doi_request.processedBy = session[:user].username
      doi_request.processingDate = DateTime.now.to_s
      error_doi_request = doi_request.update
      return error_doi_request
      rescue => e
        LOGGER.debug("WEB_UI - admin_controller - _changeRequestStatus EXCEPTION : #{e.message}\n#{e.backtrace.join("\n")}")
        raise e
      end    
  end


  

end

module DoiRequestAdministration
  extend ActiveSupport::Concern

  included do
    # Access the constant through the controller's class
    SUB_DATA_CITE_METADATA_URL = lambda { |acronym, subId| "#{AdminController::ONTOLOGIES_LIST_URL}#{acronym}/submissions/#{subId}/datacite_metadata_json" }
    DOI_REQUESTS_URL = "#{AdminController::ADMIN_URL}doi_requests_list"
  end



  def doi_requests
    response = { doi_requests: Hash.new, errors: '', success: '' }
    start = Time.now

    begin
      doi_requests_data = LinkedData::Client::HTTP.get(DOI_REQUESTS_URL, {}, raw: true)

      doi_requests_data_parsed = JSON.parse(doi_requests_data, symbolize_names: true)

      doi_requests_result = doi_requests_data_parsed.map{ |req| new_doi_request_hash(req) }

      response[:doi_requests] = doi_requests_result
      response[:success] = 'DOI requests list generated'
      LOG.add :debug, "DOI Requests List - retrieved #{response[:doi_requests].length} requests in #{Time.now - start}s"
    rescue StandardError => e
      response[:errors] = "Problem retrieving DOI Requests - #{e.message}"
    end
    response
  end

  def process_identifier_requests(success_keyword, error_keyword, action)

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
              # Get ontology submission information


              error_response = nil
              case action
              when 'process'
                error_response = process_doi(doi_request, ont_submission_id, ontology_id)
              when 'reject'
                error_response = change_request_status(doi_request, 'REJECTED') unless error_response
              else
                error_response = "action is different or nil: #{action}"
              end

              if response_error?(error_response)
                response[:errors] << "ERROR occurred in request #{request_id}:"
                errors = datacite_response_errors(response_errors(error_response))
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
    render json: response
  end

  private

  def process_doi(doi_request)
    doi_req_submission = doi_request.submission
    ont_submission_id = doi_req_submission.submissionId
    ontology_id = doi_req_submission.ontology.id
    ontology_acronym = ontology_id.split('/').last
    hash_metadata = data_cite_metadata_json(ontology_acronym, ont_submission_id)

    if doi_request.requestType == 'DOI_CREATE'
      satisfy_doi_creation_request(doi_request, hash_metadata, doi_req_submission)
    elsif doi_request.requestType == 'DOI_UPDATE'
      #satisfy_doi_update_request(doi_request, hash_metadata)
    end
  end

  def data_cite_metadata_json(ontology_acronym, ont_submission_id)
    sub_metadata_url = SUB_DATA_CITE_METADATA_URL.call(ontology_acronym, ont_submission_id)
    hash_metadata = LinkedData::Client::HTTP.get(sub_metadata_url, {}, raw: true)
    JSON.parse(hash_metadata, symbolize_names: true)
  end

  def new_doi_request_hash(req)
    {
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
  end

  def datacite_response_errors(error_hash)
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

  def satisfy_doi_creation_request(doi_request, hash_metadata, submission)
    return OpenStruct.new({ errors: ['Ontology submission not found'] }) if submission.nil?


    dc_response = DataCiteCreatorService.new(hash_metadata).call

    # If there is an error, returns it
    return dc_response['errors'] if dc_response['errors'] && !dc_response['errors'].empty?

    # If the DOI isn't into the response, returns an error
    error = "The new DOI doesn't exist in the Datacite response: check the response: dc_response"
    return error unless dc_response['data']['id'] && !dc_response['data']['id'].empty?

    # UPDATE SUBMISSION WITH NEW DOI
    new_doi = dc_response['data']['id']
    error_submission = submission.update(values: { identifier: Array(submission.identifier) + ["https://doi.org/#{new_doi}"] })

    return error_submission if response_error?(error_submission)

    # UPDATE THE STATUS OF DOI REQUEST TO "SATISFIED"
    error_doi_request = change_request_status(doi_request, 'SATISFIED')
    return error_doi_request if response_error?(error_doi_request)

    nil
  end

  def satisfy_doi_update_request(doi_request, hash_metadata)
    #Ecoportal::DataciteSrv.update_doi_information_to_datacite(hash_metadata.to_json)
  end

  def change_request_status(doi_request, new_status)
    doi_request.update(values: { status: new_status, processedBy: session[:user].id, processingDate: DateTime.now.to_s })
  end
end

module DoiRequest
  extend ActiveSupport::Concern

  def first_pending_doi_request
    if @submission
      identifier_request_list = @ontology.explore.identifier_requests
      identifier_request_list.select { |r| r.status == "PENDING" }.first
    end
  end

  def cancel_pending_doi_requests
    identifier_request_list = @ontology.explore.identifier_requests
    identifier_request = identifier_request_list.select { |r| r.status == "PENDING" }.first

    return if identifier_request.nil?

    identifier_request.status = "CANCELED"
    identifier_request.update
  end

  def doi_requested?
    params[:submission][:is_doi_requested]
  end

  def submit_new_doi_request
    request_id_hash = {
      status: "PENDING",
      requestType: "DOI_CREATE",
      requestedBy: session[:user].username,
      requestDate: DateTime.now.to_s,
      submission: @submission.id
    }
    @identifier_req_obj = LinkedData::Client::Models::IdentifierRequest.new(values: request_id_hash)
    @identifier_req_obj_saved = @identifier_req_obj.save
  end

end

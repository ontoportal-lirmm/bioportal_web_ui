module Admin::DoiRequestHelper

  def doi_request_button(ontology_id)
    return if ontology_id.nil?

    action_button("Ask for a DOI?", "/admin/doi_requests/#{ontology_id}/create")
  end

  def cancel_doi_request_button(ontology_id)
    return if ontology_id.nil?

    action_button("Cancel?", "/admin/doi_requests/#{ontology_id}/cancel")
  end

end

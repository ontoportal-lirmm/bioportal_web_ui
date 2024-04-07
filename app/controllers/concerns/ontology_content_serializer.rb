# frozen_string_literal: true

module OntologyContentSerializer
  extend ActiveSupport::Concern

  def serialize_content(ontology_acronym:, concept_id:, format:)
    if ontology_acronym && concept_id
      @format = format
      @result = ""
      @acronym = ontology_acronym
      url = content_finder_url(ontology_acronym, concept_id)
      accept_header = content_finder_accept_header(@format)
      conn = Faraday.new(url: url) do |faraday|
        faraday.headers['Accept'] = accept_header
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = "apikey token=#{get_apikey}"
      end
      response = conn.get
      if response.success?
        @result = response.body.force_encoding(Encoding::UTF_8)
      end
    end
    @result
  end

  def content_finder_url(acronym, uri)
    URI.parse("#{rest_url}/ontologies/#{acronym.strip}/resolve/#{helpers.escape(uri.strip)}")
  end

  def content_finder_accept_header(output_format)
    case output_format
    when 'json'
      "application/json"
    when 'xml'
      "application/xml"
    when 'ntriples'
      "application/n-triples"
    when 'turtle'
      "text/turtle"
    end
  end

end

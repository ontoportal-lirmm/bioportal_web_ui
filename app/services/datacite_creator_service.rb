# frozen_string_literal: true

class DataciteCreatorService < ApplicationService

  def initialize(data_cite_metadata_hash)
    @data_cite_metadata_hash = data_cite_metadata_hash

    #  configured in bioportal_config_appliance.rb
    @prefix = $DATACITE_DOI_PREFIX
    @url = $DATACITE_API_URL
    @username = $DATACITE_USERNAME
    @password = $DATACITE_PASSWORD
  end

  def call
    create_new_doi_from_data_cite(@data_cite_metadata_hash)
  end

  private

  def create_new_doi_from_data_cite(json_metadata)

    json_metadata[:prefix] = @prefix
    json_metadata[:event] = 'publish' #"draft"

    data_cite_hash = {
      data: {
        prefix: @prefix,
        type: 'dois',
        attributes: json_metadata
      }
    }

    json_metadata = data_cite_hash.to_json
    url = URI(@url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/vnd.api+json'
    request['authorization'] = "Basic #{Base64.encode64("#{@username}:#{@password}").gsub("\n", '')}"
    request.body = json_metadata

    response = http.request(request)
    json_response = response.read_body

    # convert response as json if response is a string containing a json
    json_response = JSON.parse(json_response) if json_response.is_a?(String) && json_response.start_with?('{')
    json_response
  end


  # def update_doi_information_to_datacite(json_metadata)
  #   url = URI('https://api.test.datacite.org/dois/id')
  #
  #   http = Net::HTTP.new(url.host, url.port)
  #   http.use_ssl = true
  #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  #
  #   request = Net::HTTP::Put.new(url)
  #   request['content-type'] = 'application/vnd.api+json'
  #   request['authorization'] = 'Basic TElGRVcuQ0xBOkxXRWNvcG9ydGFs'
  #
  #   request.body = '{"data":{"type":"dois","attributes":{"prefix":"10.80260"}}}'
  #
  #   response = http.request(request)
  #
  #   response.read_body
  # end
end

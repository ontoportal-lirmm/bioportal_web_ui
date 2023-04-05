require 'json'
require "base64"

# --- NEW ECOPORTAL class-----
# Utility class 
module Ecoportal  
  class DataciteSrv
    ###
    # CALL DATACITE API SERVICE TO CREATE NEW DOI AND RETURNS THE RESPONSE
    def self.createNewDoiFromDatacite(json_metadata)
      # LOGGER.debug("WEB-UI - util/datacite_srv.rb - Ecoportal::DataciteSrv.createNewDoiFromDatacite: $DATACITE_API_URL = #{$DATACITE_API_URL}\n\nDATACITE_USERNAME = #{$DATACITE_USERNAME}\n\n DATACITE_PASSWORD = #{$DATACITE_PASSWORD}\n\n DATACITE_DOI_PREFIX = #{$DATACITE_DOI_PREFIX}")
           
      url = URI($DATACITE_API_URL)
  
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
      request = Net::HTTP::Post.new(url)
      request["content-type"] = 'application/vnd.api+json'
      request["authorization"] = 'Basic ' + Base64.encode64("#{$DATACITE_USERNAME}:#{$DATACITE_PASSWORD}").gsub("\n", '')
      #request["authorization"] = 'Basic TElGRVcuQ0xBOkxXRWNvcG9ydGFs'
      request.body = json_metadata
      # request.body ='{ 
      #   "data": { 
      #        "type": "dois", 
      #        "attributes": {
      #             "prefix": "10.80260"
      #        }
      #    }
      #  }'
  
      response = http.request(request)
      #puts response.read_body
      # LOGGER.debug("WEB-UI - util/datacite_srv.rb - Ecoportal::DataciteSrv.createNewDoiFromDatacite: response = #{response.inspect} \n\n response.read_body= #{response.read_body.inspect}")
      
      json_response = response.read_body

      #convert response as json if response is a string containing a json
      json_response = JSON.parse(json_response) if json_response.is_a?(String) && json_response.start_with?('{')     

      # LOGGER.debug("WEB-UI - util/datacite_srv.rb - Ecoportal::DataciteSrv.createNewDoiFromDatacite: json_response = #{json_response.inspect}")

      return json_response
    end
    ## NOT USED JET
    # CALL DATACITE API SERVICE TO UPDATE AN EXISTING DOI CREATE BY THIS PLATFORM (IT CHECKS IF THE DOI PREFIX IS EQUAL TO THE CONFIGURED ONE) AND RETURNS THE RESPONSE
    def self.updateDoiInformationToDatacite(json_metadata)
      url = URI("https://api.test.datacite.org/dois/id")
  
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
      request = Net::HTTP::Put.new(url)
      request["content-type"] = 'application/vnd.api+json'
      request["authorization"] = 'Basic TElGRVcuQ0xBOkxXRWNvcG9ydGFs'
  
      request.body = "{\"data\":{\"type\":\"dois\",\"attributes\":{\"prefix\":\"10.80260\"}}}"
  
      response = http.request(request)
      # LOGGER.debug("WEB-UI - util/datacite_srv.rb - Ecoportal::DataciteSrv.updateDoiInformationToDatacite: response = #{response.read_body.inspect}")
      return response.read_body
    end
  end
end
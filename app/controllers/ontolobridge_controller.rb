require 'rest-client'
require 'multi_json'

class OntolobridgeController < ApplicationController

  # POST /ontolobridge
  # POST /ontolobridge.xml
  def create
    request_term
  end

  def request_term
    response = {}
    endpoint = "/RequestTerm"
    h_params = {}
    response_raw = nil
    code = 200

    begin
      params.delete("controller")
      params.delete("action")
      params.each { |k, v|
        if v === "on"
          h_params[k] = true
        else
          h_params[k] = v
        end
      }

      headers = {'Authorization' => $ONTOLOBRIDGE_AUTHENTICATION_TOKEN}
      response_raw = RestClient.post("#{$ONTOLOBRIDGE_BASE_URL}#{endpoint}", h_params, headers)
      code = response_raw.code
      response.merge!(MultiJson.load(response_raw))
    rescue RestClient::BadRequest => e
      code = 400
      response["error"] = e.message
    rescue Exception => e
      code = 500
      response["error"] = t('ontolobridge.problem_of_creating_new_term', endpoint: endpoint, class: e.class, message: e.message)
    end

    render json: [response, code], status: code
  end

  def save_new_term_instructions
    code = 200
    response = {error: '', success: ''}
    response[:success] = t('ontolobridge.new_term_instructions_saved', acronym: params['acronym'])
    ont_data = Ontology.find_by(acronym: params['acronym'])
    ont_data ||= Ontology.new
    ont_data.acronym = params['acronym']
    ont_data.new_term_instructions = params['new_term_instructions']

    begin
      ont_data.save
    rescue Exception => e
      code = 500
      response[:error] = t('ontolobridge.error_saving_new_term_instructions', acronym: params['acronym'])
    end
    sleep(1)
    render json: [response, code], status: code
  end

end

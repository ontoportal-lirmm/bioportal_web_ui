require 'rest_client'

class LOG

  # Log using local or remote methods
  #    Local: provide the log level as a symbol (:debug, :info, :error, etc)
  #    Remote: provide the request and a parameter hash
  #       Common Parameters:
  #         :ontology_id
  #         :ontology_name
  #         :virtual_id
  #         :concept_id
  #         :concept_name
  def self.add(level, message, request = nil, remote_params = nil)
    local(level, message)
  end

  private

  def self.remote(level, event, request, params)
    params = {} if params.nil?
    params = convert_params(params) unless params.empty?

    log = RestClient::Resource.new $LEGACY_REST_URL + "/log", :timeout => 30

    session = request.session
    params[:user] = session[:user].username rescue ""
    params[:userid] = session[:user].id rescue ""
    params[:ipaddress] = request.remote_ip
    params[:sessionid] = request.session_options[:id]
    params[:eventtype] = event
    params[:apikey] = $API_KEY
    params[:requesturl] = request.url

    begin
      ms = Benchmark.ms { log.post(params) }
      LOG.add :debug, "Logging action remotely (#{ms}ms)"
    rescue Exception=>e
      LOG.add :debug, "Remote logging failed: #{e.message}"
    end
  end

  # Convert parameter names before making the call. Removes underscores.
  def self.convert_params(params)
    params[:ontologyversionid] = params[:ontology_id] if params[:ontology_id]
    params[:ontologyid] = params[:virtual_id] if params[:ontologyid]
    params[:ontologyname] = params[:ontology_name] if params[:ontology_name]
    params[:conceptid] = params[:concept_id] if params[:concept_id]
    params[:conceptname] = params[:concept_name] if params[:concept_name]
    params[:query] = params[:search_term] if params[:search_term]
    params[:numsearchresults] = params[:result_count] if params[:result_count]
    params
  end

  def self.local(level, message)
    if defined? Rails.logger
      Rails.logger.send(level, message)
    else
      p "#{level} || #{message}"
    end
  end

end

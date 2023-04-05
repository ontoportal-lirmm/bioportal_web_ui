class SubmissionsController < ApplicationController

  layout :determine_layout
  before_action :authorize_and_redirect, :only=>[:edit,:update,:create,:new]

  def new
    @ontology = LinkedData::Client::Models::Ontology.get(CGI.unescape(params[:ontology_id])) rescue nil
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first unless @ontology
    @submission = @ontology.explore.latest_submission
    if @submission
      identifierRequestList = @ontology.explore.identifier_requests
      @identifierRequest = identifierRequestList.select {|r| r.status == "PENDING"}.first
    end
    @submission ||= LinkedData::Client::Models::OntologySubmission.new
    
    @ontologies_for_select = []
    LinkedData::Client::Models::Ontology.all.each do |onto|
      @ontologies_for_select << ["#{onto.name} (#{onto.acronym})", onto.id]
    end

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
  end

  def create
    
    # Make the contacts an array
    #LOGGER.debug("\n\n-------------------------\n WEB_UI - submission_controller - create")
    params[:submission][:contact] = params[:submission][:contact].values
    params[:submission][:creators] = params[:submission][:creators].values

    #LOGGER.debug("\n   >  params[:submission][:creators]=   #{params[:submission][:creators]}")

    params[:submission][:creators].each { |c|
      unless c[:creatorIdentifiers].nil?
        c[:creatorIdentifiers] = c[:creatorIdentifiers].values
      end

      unless c[:affiliations].nil?
        c[:affiliations] = c[:affiliations].values
      end
    }
    
    params[:submission][:titles] = params[:submission][:titles].values

    #LOGGER.debug("\n   >  AFTER ELABORATION: params[:submission][:creators]=   #{params[:submission][:creators]}")

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
    # LOGGER.debug("submissions_controller:create - json_metadata:#{json_metadata}")
    # Convert metadata that needs to be integer to int
    
    @metadata.map do |hash|
      #LOGGER.debug("  WEB_UI - SubmissionsController#create :\n\n  params[:submission][hash[\"attribute\"]]: #{params[:submission][hash["attribute"]]} \n\n")
      # LOGGER.debug("params[:submission][hash[\"attribute\"]]: #{params[:submission][hash["attribute"]]}")
      if hash["enforce"].include?("integer")
        if !params[:submission][hash["attribute"]].nil? && !params[:submission][hash["attribute"]].eql?("")
          params[:submission][hash["attribute"].to_s.to_sym] = Integer(params[:submission][hash["attribute"].to_s.to_sym])
          # LOGGER.debug("params[:submission][hash[\"attribute\"].to_s.to_sym]: #{params[:submission][hash["attribute"].to_s.to_sym]}")
        end
      end
      if hash["enforce"].include?("boolean") && !params[:submission][hash["attribute"]].nil?
        # LOGGER.debug("params[:submission][hash[\"attribute\"]] is boolean: #{params[:submission][hash["attribute"]]}")        
        if params[:submission][hash["attribute"]].eql?("true")
          params[:submission][hash["attribute"].to_s.to_sym] = true
        elsif params[:submission][hash["attribute"]].eql?("false")
          params[:submission][hash["attribute"].to_s.to_sym] = false
        else
          params[:submission][hash["attribute"].to_s.to_sym] = nil
        end
      else

      end
    end
    # LOGGER.debug("@@@@ explore json_metadata - END")
    # LOGGER.debug("\n\n\n  WEB_UI - SubmissionsController#create:    sto per istanziare creator\n\n\n\n")
    # creator = LinkedData::Client::Models::Creator.new(values: params[:submission][:creators][0])
    # LOGGER.debug("  WEB_UI - SubmissionsController#create:     creator=   #{creator}")

    @submission = LinkedData::Client::Models::OntologySubmission.new(values: submission_params)
    #LOGGER.debug("  WEB_UI - SubmissionsController#create:     @submission=   #{@submission.inspect}")
    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])
    #LOGGER.debug("\n\n    >   @ontology = #{@ontology.inspect}")
    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.update
    #LOGGER.debug("  WEB_UI - SubmissionsController#create :    @submission=   #{@submission.inspect} \n\n")

    @submission_saved = @submission.save
    if !@submission_saved || @submission_saved.errors
      @errors = response_errors(@submission_saved) # see application_controller::response_errors

      if @errors[:error][:uploadFilePath]
        @errors = ["Please specify the location of your ontology"]
      elsif @errors[:error][:contact]
        @errors = ["Please enter a contact"]
      end

      # the partial submissions/_form access the attributes of a submission through the dot notation;
      # however, the constructor of OntologySubmission client manages nested objects has hashes rather
      # than structs. So, if needed, we parse the parameters using the same recursive strategy adopted by the
      # HTTP client
      submission_params_h = submission_params
      submission_params_h["@type"] = "http://data.bioontology.org/metadata/OntologySubmission"
      @submission = LinkedData::Client::HTTP.recursive_struct(submission_params_h)

      render "new"
    else

      # NEW ECOPORTAL - CREATION IDENTIFIER_REQUEST - BEGIN
      # It's an object containing the request of an identifier (in our case a DOI) for submitted resource


      identifierRequestList = @ontology.explore.identifier_requests 
      identifierRequest = identifierRequestList.select {|r| r.status == "PENDING"}.first

      exist_pending_ident_req = false
      if !identifierRequest.nil?
        exist_pending_ident_req = true
        identifierRequest.status = "CANCELED"
        error = identifierRequest.update
      end


      # 1) Verify if DOI is requested
      @IdentifierReqObj_saved = nil
      if (params[:submission][:identifierType] == "None" && params[:submission][:is_doi_requested]) || exist_pending_ident_req
        # 2) Create a request identifier
        request_id_hash = {
          status: "PENDING",
          requestType: "DOI_CREATE",
          requestedBy: session[:user].username,
          requestDate: DateTime.now.to_s,
          submission: @submission_saved.id
        }
        @IdentifierReqObj = LinkedData::Client::Models::IdentifierRequest.new(values: request_id_hash)
        # 3) Save it
        @IdentifierReqObj_saved = @IdentifierReqObj.save
        # 4) assign it to submission
      end
    

    # NEW ECOPORTAL - CREATION IDENTIFIER_REQUEST - END

      #LOGGER.debug("\n\n   >  @submission_saved = #{@submission_saved.inspect} \n\n")
      redirect_to "/ontologies/success/#{@ontology.acronym}"
    end
  end

  # Called when form to "Edit submission" is submitted
  def edit
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    submissions = @ontology.explore.submissions
    @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first
    
    #LOGGER.debug("  WEB_UI - SubmissionsController#edit : \n\n  @submission = #{@submission.inspect} \n\n")

    if @submission
      identifierRequestList = @ontology.explore.identifier_requests 
      #LOGGER.debug("  WEB_UI - SubmissionsController#edit - identifierRequestList=#{identifierRequestList.inspect}")     
      @identifierRequest = identifierRequestList.select {|r| r.status == "PENDING"}.first
      #LOGGER.debug("  WEB_UI - SubmissionsController#edit -  @identifierRequest=#{@identifierRequest.inspect}")
    end
    @submission ||= LinkedData::Client::Models::OntologySubmission.new

    # LOGGER.debug("#### @ontology = #{@ontology.inspect}")

    @ontologies_for_select = []
    LinkedData::Client::Models::Ontology.all.each do |onto|
      @ontologies_for_select << ["#{onto.name} (#{onto.acronym})", onto.id]
    end

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
  end

   # When editing a submission (called when submit "Edit submission information" form)
  def update

    # Make the contacts an array
    # LOGGER.debug("@@@@submission_controller - update: params[:submission][:contact].values = #{params[:submission][:contact].values}")
    params[:submission][:contact] = params[:submission][:contact].values
    # LOGGER.debug("@@@@submission_controller - update: params[:submission][:creators].values = #{params[:submission][:creators].values}")
    #params[:submission][:creators] = params[:submission][:creators].values
    #LOGGER.debug("@@@@submission_controller BEFORE - update: params[:submission][:creators] = #{params[:submission][:creators]}")
    params[:submission][:creators] = params[:submission][:creators].values
    indexId = 1    
    params[:submission][:creators].each { |c|     
      unless c[:creatorIdentifiers].nil?
        c[:creatorIdentifiers] = c[:creatorIdentifiers].values
      end

      unless c[:affiliations].nil?
        c[:affiliations] = c[:affiliations].values
      end      
    }
    
    params[:submission][:titles] = params[:submission][:titles].values

    #LOGGER.debug("\n\n Submission_controller.rb - update: params[:submission][:creators] = #{params[:submission][:creators]}")

    @ontology = LinkedData::Client::Models::Ontology.get(params[:submission][:ontology])
    submissions = @ontology.explore.submissions
    @submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first

    # Get the submission metadata from the REST API
    json_metadata = JSON.parse(Net::HTTP.get(URI.parse("#{REST_URI}/submission_metadata?apikey=#{API_KEY}")))
    @metadata = json_metadata
    # Convert metadata that needs to be integer to int
    @metadata.map do |hash|
      #LOGGER.debug("  WEB_UI - SubmissionsController#update :\n\n  params[:submission][hash[\"attribute\"]]: #{params[:submission][hash["attribute"]]} \n\n")
      if hash["enforce"].include?("integer")
        if !params[:submission][hash["attribute"]].nil? && !params[:submission][hash["attribute"]].eql?("")
          params[:submission][hash["attribute"].to_s.to_sym] = Integer(params[:submission][hash["attribute"].to_s.to_sym])
        end
      end
      if hash["enforce"].include?("boolean") && !params[:submission][hash["attribute"]].nil?
        if params[:submission][hash["attribute"]].eql?("true")
          params[:submission][hash["attribute"].to_s.to_sym] = true
        elsif params[:submission][hash["attribute"]].eql?("false")
          params[:submission][hash["attribute"].to_s.to_sym] = false
        else
          params[:submission][hash["attribute"].to_s.to_sym] = nil
        end
      end
    end
    @submission.update_from_params(submission_params)

    # if !@IdentifierReqObj_saved.nil?
    #   @submission.identifierRequest = [] if @submission.identifierRequest.nil?
    #   LOGGER.debug("  WEB_UI - SubmissionsController#update : \n\n  added IdentifierRequest to @submission\n")
    #   @submission.identifierRequest << @IdentifierReqObj_saved.requestId
    # end
    
    # Update summaryOnly on ontology object
    @ontology.summaryOnly = @submission.isRemote.eql?("3")
    @ontology.update

    #LOGGER.debug("  WEB_UI - SubmissionsController#update : \n\n  @submission = #{@submission.inspect} \n\n")

    error_response = @submission.update

    if error_response
      @errors = response_errors(error_response) # see application_controller::response_errors
    else

      # NEW ECOPORTAL - CREATION IDENTIFIER_REQUEST - BEGIN
      # It's an object containing the request of an identifier (in our case a DOI) for submitted resource

      # 1) Verify if DOI is requested      
      if (params[:submission][:identifierType] == "None" && params[:submission][:is_doi_requested])
        # 2) Create a request identifier
        request_id_hash = {
          status: "PENDING",
          requestType: "DOI_CREATE",
          requestedBy: session[:user].username,
          requestDate: DateTime.now.to_s,
          submission:  @submission.id
        }
        @IdentifierReqObj = LinkedData::Client::Models::IdentifierRequest.new(values: request_id_hash)
        #LOGGER.debug("\n\n Submission_controller.rb - update: @IdentifierReqObj = #{@IdentifierReqObj.nil? ? "Nil" : @IdentifierReqObj.inspect}")
        # 3) Save it
        @IdentifierReqObj_saved = @IdentifierReqObj.save

        # if !@IdentifierReqObj_saved.nil?
        #   LOGGER.debug("\n\n Submission_controller.rb - update: @IdentifierReqObj_saved = #{@IdentifierReqObj_saved.nil? ? "Nil" : @IdentifierReqObj_saved.inspect}")
        # end

        # 4) assign it to submission
      end
    

    # NEW ECOPORTAL - CREATION IDENTIFIER_REQUEST - END
       redirect_to "/ontologies/#{@ontology.acronym}"
    end
  end

  private

  def submission_params
    p = params.require(:submission).permit(:ontology, :description, :hasOntologyLanguage, :prefLabelProperty,
                                           :synonymProperty, :definitionProperty, :authorProperty, :obsoleteProperty,
                                           :obsoleteParent, :version, :status, :released, :isRemote, :pullLocation,
                                           :filePath, { contact:[:name, :email] }, :homepage, :documentation,
                                           :publication,
                                           :identifier, :identifierType, :is_doi_requested,
                                           { creators: [:nameType, :givenName, :familyName, :creatorName,
                                             { creatorIdentifiers: [:nameIdentifierScheme, :schemeURI, :nameIdentifier]},
                                             { affiliations: [:affiliationIdentifierScheme, :affiliationIdentifier, :affiliation]}] },
                                           { titles: [:title, :lang, :titleType]},
                                           :publisher, :publicationYear, :resourceType, :resourceTypeGeneral)
    p.to_h
  end

end

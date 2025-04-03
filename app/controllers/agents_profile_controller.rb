class AgentsProfileController < ApplicationController

    layout :determine_layout

    def index
    end

    def details
      @agent = find_agent(id = params[:id])
      @agent_stats = AgentStatisticsCalculatorComponent.new(@agent).stats
      
      mapping = { "http://omv.ontoware.org/2005/05/ontology#hasContributor" => "Contributor", "http://omv.ontoware.org/2005/05/ontology#hasCreator" => "Creator", "http://purl.org/dc/terms/publisher" => "Publisher", "http://xmlns.com/foaf/0.1/fundedBy" => "Funded By", "http://schema.org/copyrightHolder" =>  "Copyright Holder", "http://schema.org/translator" => "Translator", "http://omv.ontoware.org/2005/05/ontology#endorsedBy" => "Endorsed By", "http://purl.org/pav/curatedBy" => "Curator"}
      @agentOntologies = @agent.usages.to_h.each_with_object({}) do |(key, value), hash|
        if (match = key.to_s.match(%r{/ontologies/([^/]+)/submissions}))
          ontology_acronym = match[1]
          hash[ontology_acronym] = value.map { |url| mapping[url] }
        end
      end      

    end
  
    def find_agent(id = params[:id])
      id = helpers.unescape(id)
      @agent = LinkedData::Client::Models::Agent.find(id.split('/').last, {include: 'all'})
      not_found("Agent with id #{id} not found") if @agent.nil?
      @agent
    end  
  end


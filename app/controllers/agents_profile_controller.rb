class AgentsProfileController < ApplicationController

    layout :determine_layout

    def index
    end

    def details
      @agent = find_agent(id = params[:id])
      @agent_properties = agent_to_hash(@agent)   
      @agent_stats = AgentStatisticsCalculatorComponent.new(@agent).stats

      mapping = { "http://omv.ontoware.org/2005/05/ontology#hasContributor" => "Contributor", "http://omv.ontoware.org/2005/05/ontology#hasCreator" => "Creator", "http://purl.org/dc/terms/publisher" => "Publisher" }
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
  
    def agent_to_hash(agent, attributes: nil, keep_at_prefix: false, compact: true)
      attributes ||= %i[@name @agentType @acronym @email @homepage @affiliations @identifiers]
    
      {}.tap do |hash|
        attributes.each do |attr|
          next unless agent.instance_variable_defined?(attr)
    
          value = agent.instance_variable_get(attr)
    
          value = case value
                  when Array then value.map { |v| v.respond_to?(:to_h) ? v.to_h : v }
                  when OpenStruct then value.to_h
                  else value
                  end
    
          key = keep_at_prefix ? attr.to_s : attr.to_s.delete('@')
          if key == "identifiers" && value.is_a?(Array)
            hash[key] = transform_identifiers(value)
            
          else
            hash[key] = value
          end
        end
    
        hash.compact! if compact
      end
    end
    
    def transform_identifiers(identifiers)
      Array(identifiers).each_with_object({}) do |id, hash|
        agency = id[:schemaAgency].to_s
        notation = id[:notation].to_s

        if agency.present? && notation.present?
          return case agency.upcase
                        when "ORCID" then "https://orcid.org/#{notation}"
                        when "ROR" then "https://ror.org/#{notation}"
                        else notation
                        end
        end
      end
    end
    
  end


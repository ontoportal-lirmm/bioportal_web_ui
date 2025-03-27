class AgentStatisticsCalculatorComponent
    def initialize(agent)
      @agent = agent
    end
  
    def stats
      creator_count = 0
      contributor_count = 0
      publisher_count = 0
  
      # Access the usages OpenStruct
      usages = @agent.usages
      
      # Skip if usages is nil or doesn't respond to each_pair
      if usages.respond_to?(:each_pair)
        usages.each_pair do |_key, values|
          next unless values.is_a?(Array)
          
          values.each do |value|
            case value
            when /hasCreator/    then creator_count += 1
            when /hasContributor/ then contributor_count += 1
            when /publisher/ then publisher_count += 1
            end
          end
        end
      end
  
      total = creator_count + contributor_count + publisher_count
  
      {
        total: total,
        creator_count: creator_count,
        contributor_count: contributor_count,
        publisher_count: publisher_count,
      }
    end
  
    private
  

  end
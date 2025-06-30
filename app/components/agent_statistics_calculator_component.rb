class AgentStatisticsCalculatorComponent
  CONTRIBUTION_MAPPING = {
    /hasCreator/ => :creator_count,
    /hasContributor/ => :contributor_count,
    /publisher/ => :publisher_count,
    /fundedBy/ => :funded_by_count,
    /copyrightHolder/ => :copyright_holder_count,
    /translator/ => :translator_count,
    /endorsedBy/ => :endorsed_by_count,
    /curatedBy/ => :endorsed_by_count
  }.freeze

  def initialize(agent)
    @agent = agent
  end

  def stats
    counts = Hash.new(0)

    # Access the usages OpenStruct
    usages = @agent.usages

    # Skip if usages is nil or doesn't respond to each_pair
    if usages.respond_to?(:each_pair)
      usages.each_pair do |_key, values|
        next unless values.is_a?(Array)

        values.each do |value|
          CONTRIBUTION_MAPPING.each do |pattern, key|
            counts[key] += 1 if value.match?(pattern)
          end
        end
      end
    end
    
    counts[:total] = counts.values.sum

    counts
  end
end

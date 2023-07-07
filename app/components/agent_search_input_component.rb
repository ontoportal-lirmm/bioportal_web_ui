# frozen_string_literal: true

class AgentSearchInputComponent < ViewComponent::Base

  def initialize(id:, organization_only: false )
    super
    @id = id
    @organization_only = organization_only
  end
end

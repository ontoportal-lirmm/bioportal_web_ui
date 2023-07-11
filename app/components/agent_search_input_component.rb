# frozen_string_literal: true

class AgentSearchInputComponent < ViewComponent::Base

  def initialize(id:, agent_type: nil, name_prefix: nil, parent_id: , edit_on_modal: false)
    super
    @id = id
    @agent_type = agent_type
    @name_prefix = name_prefix
    @parent_id = parent_id
    @edit_on_modal = edit_on_modal
  end
end

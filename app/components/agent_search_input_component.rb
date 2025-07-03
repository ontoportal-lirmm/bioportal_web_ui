# frozen_string_literal: true

class AgentSearchInputComponent < ViewComponent::Base

  def initialize(id:, agent_type: nil, name_prefix: nil, parent_id: , show_affiliations: true, editable: true, edit_on_modal: false, deletable: false, create_new_agent_action: true)
    @id = id
    @agent_type = agent_type
    @name_prefix = name_prefix
    @parent_id = parent_id
    @editable = editable
    @edit_on_modal = edit_on_modal
    @show_affiliations = show_affiliations
    @deletable = deletable
    @create_new_agent_action = create_new_agent_action
  end
end

# frozen_string_literal: true

class NestedAgentSearchInputComponent < ViewComponent::Base

  include Turbo::FramesHelper, AgentHelper

  def initialize(label: nil, agents:, agent_type:, name_prefix:, show_affiliations: true, editable: true, edit_on_modal: false, parent_id: nil, create_new_agent_action: true)
    @agents = agents
    @agent_type = agent_type
    @name_prefix = name_prefix
    @editable = editable
    @edit_on_modal = edit_on_modal
    @parent_id = parent_id
    @label = label
    @show_affiliations = show_affiliations
    @create_new_agent_action = create_new_agent_action
  end
end

# frozen_string_literal: true

class NestedAgentSearchInputComponent < ViewComponent::Base

  include Turbo::FramesHelper, AgentHelper

  def initialize(label: nil, agents:, agent_type:, name_prefix:, edit_on_modal: false, parent_id: nil)
    super
    @agents = agents
    @agent_type = agent_type
    @name_prefix = name_prefix
    @edit_on_modal = edit_on_modal
    @parent_id = parent_id
    @label = label
  end
end

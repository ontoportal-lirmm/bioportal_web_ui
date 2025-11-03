# frozen_string_literal: true

class TeamController < ApplicationController
  layout :determine_layout

  def index
    @title = "#{t('layout.footer.team')} - #{helpers.portal_name}"
    @team_members = load_team_members
  end

  private

  def load_team_members
    team_config_path = Rails.root.join('config', 'team.yml')
    return [] unless File.exist?(team_config_path)

    YAML.load_file(team_config_path)['team_members'] || []
  rescue => e
    Rails.logger.error "Error loading team config: #{e.message}"
    []
  end
end

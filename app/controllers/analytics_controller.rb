# frozen_string_literal: true

require 'csv'

class AnalyticsController < ApplicationController
  def track
    params = analytic_params
    Analytics.create do |a|
      a.segment = params[:segment]
      a.action = params[:analytics_action]
      a.bp_slice = @subdomain_filter[:active] ? @subdomain_filter[:acronym] : nil
      a.ip = request.remote_ip
      a.user = session[:user].nil? ? nil : session[:user].id
      a.params = params.except(:segment, :analytics_action)
    end
    head :ok
  end

  def search_result_clicked
    if current_user_admin?
      clicks = Analytics.where(segment: 'search', action: 'result_clicked').all
      rows = populate_csv(clicks)
      respond_with_csv_file(rows, 'search_result_clicks')
    else
      render status: :unauthorized,
             json: { error: 'You are not authorized to access this resource. Please log in as an administrator.' }
    end
  end

  private

  def analytic_params
    params.permit(:segment, :analytics_action, :query, :concept_id, :additional_result, :position,
                  { higher_ontologies: [] }, :ontology_clicked)
  end

  def populate_csv(clicks)
    rows = []
    rows << %w[
      query position_clicked ontology_clicked higher_rated_ontologies additional_result exact_match
      concept_id time user bp_slice ip_address
    ] # header row

    clicks.each do |click|
      next if click.params.empty?

      params = click.params
      rows << [
        params['query'].delete('\t'),
        params['position'],
        params['ontology_clicked'],
        params['higher_ontologies'].nil? ? '' : click.params['higher_ontologies'].join(';'),
        params['additional_result'],
        params['exact_match'],
        params['concept_id'],
        click.created_at.to_formatted_s,
        click.user.to_s,
        click.bp_slice,
        click.ip
      ]
    end
    rows
  end

  def respond_with_csv_file(rows, filename = 'output')
    output = String.new('')
    rows.each do |row|
      output << row.to_csv.force_encoding('UTF-8')
    end
    send_data output, type: 'text/csv', disposition: "attachment; filename=#{filename}.csv"
  end
end

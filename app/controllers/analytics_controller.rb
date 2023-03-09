require "csv"

class AnalyticsController < ApplicationController
  def track
    entry = Analytics.new
    entry.segment = params[:segment]
    entry.action = params[:analytics_action]
    entry.bp_slice = @subdomain_filter[:active] ? @subdomain_filter[:acronym] : nil
    entry.ip = request.remote_ip
    entry.user = session[:user].nil? ? nil : session[:user].id
    entry.params = params.except(:segment, :analytics_action, :action, :controller)
    entry.save
    head :ok
  end

  def search_result_clicked
    clicks = Analytics.where(:segment => "search", :action => "result_clicked").all
    rows = [["query", "position_clicked", "ontology_clicked", "higher_rated_ontologies", "additional_result", "exact_match", "concept_id", "time", "user", "bp_slice", "ip_address"]]
    clicks.each do |click|
      next if click.params.empty?
      rows << [
        click.params["query"].delete("\t"),
        click.params["position"],
        click.params["ontology_clicked"],
        click.params["higher_ontologies"].nil? ? "" : click.params["higher_ontologies"].join(";"),
        click.params["additional_result"],
        click.params["exact_match"],
        click.params["concept_id"],
        click.created_at,
        click.user,
        click.bp_slice,
        click.ip,
      ]
    end
    respond_with_csv_file(rows, "search_result_clicked")
  end

  def user_intention_surveys
    surveys = Analytics.where(:segment => "users", :action => "intention_survey").all
    rows = [["page", "response", "email", "time", "user", "bp_slice", "ip_address"]]
    surveys.each do |survey|
      rows << [
        survey.params["page"],
        survey.params["intention_response"],
        survey.params["contest_email"],
        survey.created_at,
        survey.user,
        survey.bp_slice,
        survey.ip,
      ]
    end
    respond_with_csv_file(rows, "user_intention_survey")
  end

  private

  def respond_with_csv_file(rows, filename = "output")
    output = ""
    rows.each do |row|
      output << row.to_csv.force_encoding("UTF-8")
    end
    send_data output, :type => "text/csv", :disposition => "attachment; filename=#{filename}.csv"
  end
end

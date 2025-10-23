class Admin::AnalyticsController < ApplicationController
  before_action :authorize_admin
  layout :determine_layout

  def index
    @users = LinkedData::Client::Models::User.all
    @ontology_visits = ontology_visits_data
    @users_visits = user_visits_data
    @page_visits = page_visits_data
    @ontologies_problems_count = helpers.get_ontologies_report()[:ontologies]&.count { |_, v| v[:problem] } || 0
  end

  private

  def user_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/users", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }

    return visits_data if analytics.empty?

    analytics.sort.each do |year, year_data|
      year_data.each do |month, value|
        visits_data[:visits] << value
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    visits_data
  end

  def ontology_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/ontologies", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }
    @new_ontologies_count = []
    @ontologies_count = 0

    return visits_data if analytics.empty?

    aggregated_data = {}
    analytics.each do |acronym, years_data|
      current_year_count = 0
      previous_year_count  = 0
      years_data.each do |year, months_data|
        previous_year_count += current_year_count
        current_year_count = 0
        aggregated_data[year] ||= {}
        months_data.each do |month, value|
          if aggregated_data[year][month]
            aggregated_data[year][month] += value
          else
            aggregated_data[year][month] = value
          end
          current_year_count += value
        end
      end
      @ontologies_count += 1
      if previous_year_count.zero? && current_year_count.positive?
        @new_ontologies_count << [acronym]
      end
    end


    aggregated_data.sort.each do |year, year_data|
      year_data.each do |month, value|
        visits_data[:visits] << value
        visits_data[:labels] << DateTime.parse("#{year}/#{month}").strftime("%b %Y")
      end
    end
    visits_data
  end

  def page_visits_data
    begin
      analytics = JSON.parse(LinkedData::Client::HTTP.get("#{rest_url}/data/analytics/page_visits", {}, raw: true))
    rescue
      analytics = {}
    end
    visits_data = { visits: [], labels: [] }

    return visits_data if analytics.empty?

    analytics.each do |path, count|
      visits_data[:labels] << path
      visits_data[:visits] << count
    end
    visits_data
  end
end

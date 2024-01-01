class StatisticsController < ApplicationController
  include StatisticsHelper, ComponentsHelper

  layout :determine_layout

  def index
    projects = LinkedData::Client::Models::Project.all({include: 'created'})
    users = LinkedData::Client::Models::User.all({include: 'created'})
    year_month_count,  @year_month_visits =  ontologies_by_year_month
    @merged_data = merge_time_evolution_data([group_by_year_month(users),
                                              group_by_year_month(projects),
                                              year_month_count])
  end
end

class VisitsController < ApplicationController
  layout :determine_layout

  def index
    @ontologies_views = LinkedData::Client::Models::Ontology.all(include_views: true)
    @ontologies = @ontologies_views.select { |o| !o.viewOf }
    @ontologies_hash = Hash[@ontologies_views.map { |o| [o.acronym, o] }]
    @analytics = LinkedData::Client::Analytics.last_month
  end
end

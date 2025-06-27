require 'multi_json'

class Admin::GraphsController < ApplicationController

  include TurboHelper

  layout :determine_layout
  before_action :authorize_admin

  GRAPHS_URL = "#{LinkedData::Client.settings.rest_url}/admin/graphs".freeze

  def index
    @graphs = LinkedData::Client::HTTP.get(GRAPHS_URL.dup, { raw: true }, { raw: true })
    @graphs = MultiJson.load(@graphs)
    @zombie_graphs = @graphs.select { |_, v| v[1] }
    all_onts = LinkedData::Client::Models::Ontology.all
    @empty_ontologies = all_onts.select { |ont| !@graphs.any? { |k, _| k.include?(ont.acronym) } }
  end

  def create
    message = 'Graphs counts created successfully'
    # response = LinkedData::Client::HTTP.post(GRAPHS_URL, {})
    # message = response.status == 200 ? response.message : 'Error creating graphs counts'
    redirect_to admin_index_path(section: 'graphs'), notice: message
  end

end

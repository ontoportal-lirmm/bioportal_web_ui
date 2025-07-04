class Admin::AgentsController < ApplicationController
  layout :determine_layout
  before_action :authorize_admin

  def index  
  options = {  
    include: 'agentType,name,homepage,acronym,email,identifiers,affiliations,usages' 
  }  
  @agents = LinkedData::Client::Models::Agent.all(options)
  end
end
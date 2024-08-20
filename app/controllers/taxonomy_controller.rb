class TaxonomyController < ApplicationController

  layout :determine_layout

  def index
    @groups = LinkedData::Client::HTTP.get('/groups')
    
  end

end

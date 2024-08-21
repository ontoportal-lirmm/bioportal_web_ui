class TaxonomyController < ApplicationController

  layout :determine_layout

  def index
    @groups = LinkedData::Client::HTTP.get('/groups')

    slices = LinkedData::Client::HTTP.get('/slices')
    slices_acronyms = slices.map { |slice| slice.acronym.downcase }
    @groups.each do |group|
      if slices_acronyms.include?(group.acronym.downcase)
        group[:is_slice] = true
      end
    end

    
  end

end

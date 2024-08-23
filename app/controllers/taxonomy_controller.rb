class TaxonomyController < ApplicationController

  layout :determine_layout

  def index
    @groups = LinkedData::Client::Models::Group.all

    slices = LinkedData::Client::Models::Slice.all
    slices_acronyms = slices.map { |slice| slice.acronym.downcase }
    @groups.each do |group|
      if slices_acronyms.include?(group.acronym.downcase)
        group[:is_slice] = true
      end
    end

    @categories = LinkedData::Client::Models::Category.all(display: 'name,acronym,description,ontologies')
  end

end

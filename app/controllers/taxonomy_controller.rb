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

    @categories = LinkedData::Client::Models::Category.all(display: 'name,acronym,description,ontologies,parentCategory')
    @categories = nest_categories_children(@categories)
  end

  def nest_categories_children(categories)
    category_index = {}
    categories.each do |category|
      category_index[category[:id]] = category
    end
    categories.each do |category|
      if category.parentCategory
        parent = category_index[category.parentCategory]
        parent[:children] ||= []
        parent[:children] << category
      end
    end
    categories.reject! { |category| category.parentCategory }
    categories
  end

end

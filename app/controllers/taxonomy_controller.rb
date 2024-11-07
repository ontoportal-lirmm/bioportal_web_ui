class TaxonomyController < ApplicationController

  layout :determine_layout

  def index
    initialize_taxonomy
    @category_section_active = request.path.eql?('/categories')
  end

  private
  def initialize_taxonomy
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
    ontologies = LinkedData::Client::Models::Ontology.all
    @ontologies_names = {}
    ontologies.each do |o|
      @ontologies_names[o.id] = o.name
    end
  end

  def nest_categories_children(categories)
    category_index = {}
    categories.each do |category|
      category_index[category[:id]] = category
    end
    categories.each do |category|
      category[:parentCategory].each do |parent_id|
        parent = category_index[parent_id]
        parent[:children] ||= []
        parent[:children] << category
      end
    end
    categories.reject! { |category| category[:parentCategory]&.any? }
    categories
  end

end

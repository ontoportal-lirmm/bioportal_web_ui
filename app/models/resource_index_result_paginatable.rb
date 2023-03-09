class ResourceIndexResultPaginatable < WillPaginate::Collection
  attr_accessor :totalResults, :offset, :limit, :acronym

  def initialize(hash)
    return if hash.nil?

    # Our custom attributes
    self.totalResults = hash.pageCount * hash.collection.length
    self.offset = hash.page * hash.collection.length
    self.limit = hash.collection.length

    # Fill out attributes needed by will_paginate
    @current_page = hash.page
    @per_page = self.limit
    self.total_entries = self.totalResults

    # Put the array elements in place
    self.replace(hash.collection)
  end
end

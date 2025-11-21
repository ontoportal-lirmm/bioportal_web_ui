# frozen_string_literal: true
class SampleQueriesEditComponent < ViewComponent::Base
  include ModalHelper, ApplicationHelper
  def initialize(sample_queries: [], graph: nil)
    super
    @sample_queries = sample_queries
    @graph = graph
  end
end
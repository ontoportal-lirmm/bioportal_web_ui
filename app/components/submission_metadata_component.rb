# frozen_string_literal: true

class SubmissionMetadataComponent < ViewComponent::Base

  def initialize(values: [])
    super
    @values = values
  end
end

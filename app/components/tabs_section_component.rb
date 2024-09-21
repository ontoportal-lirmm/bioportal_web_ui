class TabsSectionComponent < ViewComponent::Base
  include UrlsHelper
  include ApplicationHelper

  def initialize(ontology:, section_title:, section_content:)
    @ontology = ontology
    @section_title = section_title
    @section_content = section_content
  end

  def apikey
    get_apikey
  end
end

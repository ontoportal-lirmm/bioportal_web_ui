class Display::TaxonomyCardComponent < ViewComponent::Base
  def initialize(taxonomy:)
    @taxonomy = taxonomy
  end
end

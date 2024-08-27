class Display::TaxonomyCardComponent < ViewComponent::Base
  def initialize(taxonomy:)
    @taxonomy = taxonomy
  end

  def reveal_id
    @taxonomy.id
  end
end

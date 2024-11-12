class Display::TaxonomyCardComponent < ViewComponent::Base
  require 'uri'
  def initialize(taxonomy: , ontologies_names: )
    @taxonomy = taxonomy
    @ontologies_names = ontologies_names
  end

  def reveal_id
    @taxonomy.id
  end

  def description_is_url?
    uri_regex = URI::DEFAULT_PARSER.make_regexp
    @taxonomy.description.match?(/\A#{uri_regex}\z/)
  end
end

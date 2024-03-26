module InternationalisationHelper

  # Implement logic to make the term 'ontology' configurable throughout the portal,
  # allowing it to be replaced with the variable $RESOURCE_TERM
  def self.t(*args)
    return I18n.t(*args) unless $RESOURCE_TERM

    translation = I18n.t(*args).downcase
    term = I18n.t("resource_term.ontology")
    plural_term = I18n.t("resource_term.ontology_plural")
    single_term = I18n.t("resource_term.ontology_single")
    resource = I18n.t("resource_term.#{$RESOURCE_TERM}")
    resources = I18n.t("resource_term.#{$RESOURCE_TERM}_plural")
    a_resource = I18n.t("resource_term.#{$RESOURCE_TERM}_single")

    if translation.include?(term) && resource
      replacement = resource.capitalize
      replacement = resource if translation.include?(term)
      if translation.include?(single_term)
        term = single_term
        replacement = a_resource
      end
      translation.gsub(term, replacement)

    elsif translation.include?(plural_term) && resources
      replacement = resources.capitalize
      replacement = resources if translation.include?(plural_term)
      translation.gsub(plural_term, replacement)
    else
      I18n.t(*args)
    end
  end

  def t(*args)
    InternationalisationHelper.t(*args)
  end

end

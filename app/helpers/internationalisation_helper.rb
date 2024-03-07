module InternationalisationHelper

  def t(*args)
    translation = I18n.t(*args).downcase
    term = I18n.t("resource_term.ontology")
    plural_term = I18n.t("resource_term.ontology_plural")
    single_term = I18n.t("resource_term.ontology_single")
    resource = I18n.t("resource_term.#{$RESOURCE_TERM}")
    resources = I18n.t("resource_term.#{$RESOURCE_TERM}_plural")
    a_resource = I18n.t("resource_term.#{$RESOURCE_TERM}_single")

    if translation.include?(term)
      replacement = resource.capitalize
      replacement = resource if translation.include?(term)
      if translation.include?(single_term)
        term = single_term
        replacement = a_resource
      end
      translation.gsub(term, replacement)

    elsif translation.include?(plural_term)
      replacement = resources.capitalize
      replacement = resources if translation.include?(plural_term)
      translation.gsub(plural_term, replacement)
    else
      I18n.t(*args)
    end
  end

end

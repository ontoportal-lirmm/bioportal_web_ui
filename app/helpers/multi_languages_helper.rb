module MultiLanguagesHelper

  def language_hash(concept_label)

    return concept_label.first if concept_label.is_a?(Array)
    return concept_label.to_h.reject { |key, _| %i[links context].include?(key) } if concept_label.is_a?(OpenStruct)

    concept_label
  end

  def sorted_labels(labels)
    Array(labels).sort_by { |label| label['prefLabel'].is_a?(String) ? label['prefLabel'] : label['prefLabel'].last }
  end

  def select_language_label(concept_label, platform_languages = %i[en fr])
    concept_value = nil

    concept = language_hash(concept_label)

    return ['@none', concept] if concept.is_a?(String)

    concept = concept.to_h

    platform_languages.each do |lang|
      if concept[lang]
        concept_value = [lang, concept[lang]]
        break
      end
    end

    concept_value || concept.to_a.first
  end

  def main_language_label(label)
    select_language_label(label)&.last
  end

  def display_in_multiple_languages(label)
    label = language_hash(label)

    if label.nil?
      return render Display::AlertComponent.new(message: t('ontology_details.concept.no_preferred_name_for_selected_language'),
                                                type: "warning",
                                                closable: true)
    end

    return content_tag(:p, label) if label.is_a?(String)

    raw(label.map do |key, value|
      content_tag(:div, class: 'd-flex align-items-center') do
        concat content_tag(:p, Array(value).join(', '), class: 'm-0')

        unless key.to_s.upcase.eql?('NONE') || key.to_s.upcase.eql?('@NONE')
          concat content_tag(:span, key.upcase, class: 'badge badge-secondary ml-1')
        end
      end
    end.join)
  end

  def selected_language_label(label)
    language_hash(label).values.first
  end
end

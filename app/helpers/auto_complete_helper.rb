module AutoCompleteHelper

  def ontologies_autocomplete
    render OntologySearchInputComponent.new
  end

  def ontologies_content_autocomplete(id: '', name: '', search: '', ontologies: [], types: [], search_icon_type: 'home')
    render SearchInputComponent.new(id: id, name: name, ajax_url: "#{ajax_search_ontologies_content_path}?ontologies=#{ontologies.join(',')}&types=#{types.join(',')}&search=#{search}",
                                    item_base_url: "", id_key: 'id', placeholder: t("ontologies.ontology_search_prompt"),
                                    use_cache: false, search_icon_type: search_icon_type,
                                    actions_links: { search_ontology_content: "/search?query=o", browse_all_ontologies: "/ontologies?search=o" }) do |s|
      s.template do
        link_to "LINK", class: "search-content", 'data-turbo-frame': '_top' do
          content_tag(:div, class: 'search-element home-searched-ontology flex-column') do
            content_tag(:p, "LABEL") + content_tag(:small, "NAME") + content_tag(:small, "ACRONYM", class: 'text-primary')
          end + content_tag(:p, "TYPE", class: 'home-result-type')
        end
      end
    end
  end

  def ontology_content_autocomplete(search: '', ontologies: [], types: [])
    ontologies_content_autocomplete(ontologies: ontologies, types: types, search: "#{search}")
  end

end
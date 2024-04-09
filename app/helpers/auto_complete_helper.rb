module AutoCompleteHelper

  def ontologies_autocomplete
    render OntologySearchInputComponent.new
  end

  def ontologies_content_autocomplete(id: '', name: '')
    render SearchInputComponent.new(id: id, name: name, ajax_url: ajax_search_ontologies_content_path(search: ''),
                                    item_base_url: "", id_key: 'id', placeholder: "Search everywhere anything",
                                    use_cache: false,
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
end
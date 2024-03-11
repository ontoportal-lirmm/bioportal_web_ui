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

  def agents_autocomplete(id, type, parent_id: '', name_prefix: '', edit_on_modal: false, deletable: true)
    render AgentSearchInputComponent.new(id: id, agent_type: type,
                                         parent_id: parent_id,
                                         edit_on_modal: edit_on_modal,
                                         name_prefix: name_prefix,
                                         deletable: deletable)
  end
end
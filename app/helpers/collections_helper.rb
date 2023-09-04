module CollectionsHelper


  def get_collections(ontology, add_colors: false)
    collections = ontology.explore.collections(language: request_lang)
    generate_collections_colors(collections) if add_colors
    collections
  end

  def get_collection(ontology, collection_uri)
    ontology.explore.collections({ include: 'all', language: request_lang},collection_uri)
  end

  def get_collection_label(collection)
    if collection['prefLabel'].nil? || collection['prefLabel'].empty?
      extract_label_from(collection['@id']).html_safe
    else
      collection['prefLabel']
    end
  end

  def get_collections_labels(collections, main_uri = '')

    selected_label = nil
    collections_labels = []
    collections.each do  |x|
      id = x['@id']
      label = select_language_label(get_collection_label(x))
      if id.eql? main_uri
        selected_label = { 'prefLabel' => label, '@id' => id }
      else
        collections_labels.append( { 'prefLabel' => label, '@id' => id , 'color' => x['color'] })
      end
    end

    collections_labels = sorted_labels(collections_labels)
    collections_labels.unshift selected_label if selected_label
    [collections_labels, selected_label]
  end

  def no_collections?
    @collections.nil? || @collections.empty?
  end

  def no_collections_alert
    render Display::AlertComponent.new do
      "#{@ontology.acronym} does not contain collections (skos:Collection)"
    end
  end

  def collection_path(collection_id = '', language = '')
    "/ontologies/#{@ontology.acronym}/collections/show?id=#{escape(collection_id)}&language=#{language}"
  end

  def request_collection_id
    params[:id] || params[:collection_id] || params[:concept_collection]
  end

  def sort_collections_label(collections_labels)
    sorted_labels(collections_labels)
  end

  def link_to_collection(collection, selected_collection_id)
    pref_label_lang, pref_label_html = get_collection_label(collection)
    tooltip  = pref_label_lang.to_s.eql?('@none') ? '' :  "data-controller='tooltip' data-tooltip-position-value='right' title='#{pref_label_lang.upcase}'"
    <<-EOS
          <a id="#{collection['@id']}" href="#{collection_path(collection['@id'], request_lang)}" 
            data-turbo="true" data-turbo-frame="collection" data-collectionid="#{collection['@id']}"
           #{tooltip}
            class="#{selected_collection_id.eql?(collection['@id']) ? 'active' : nil}">
              #{pref_label_html}
          </a>
    EOS
  end

  private

  def generate_collections_colors(collections)
    collections.each do |c|
      c.color = format('#%06x', (rand * 0xffffff))
    end
  end
end


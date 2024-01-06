module SearchAggregator
  extend ActiveSupport::Concern
  BLACKLIST_FIX_STR = [
    "https://",
    "http://",
    "bioportal.bioontology.org/ontologies/",
    "purl.bioontology.org/ontology/",
    "purl.obolibrary.org/obo/",
    "swrl.stanford.edu/ontologies/",
    "mesh.owl" # Avoids RH-MESH subordinate to MESH
  ]

  BLACKLIST_REGEX = [
    /abnormalities/i,
    /biological/i,
    /biology/i,
    /bioontology/i,
    /clinical/i,
    /extension/i,
    /\.gov/i,
    /ontology/i,
    /ontologies/i,
    /semanticweb/i
  ]

  def aggregate_results(query, results)
    ontologies = aggregate_by_ontology(results)
    grouped_results = add_subordinate_ontologies(query, ontologies)
    all_ontologies = LinkedData::Client::Models::Ontology.all(include: 'acronym,name', include_views: true, display_links: false, display_context: false)

    grouped_results.map do |group|
      format_search_result(group, all_ontologies)
    end
  end

  def format_search_result(result, ontologies)
    same_ont = result[:same_ont]
    same_cls = result[:sub_ont]
    result = same_ont.shift
    ontology = result.links['ontology'].split('/').last
    {
      root: search_result_elem(result, ontology, ontology_name_acronym(ontologies, ontology)),
      descendants: same_ont.map { |x| search_result_elem(x, ontology, '') },
      reuses: same_cls.map do |x|
        format_search_result(x, ontologies)
      end
    }
  end

  private

  def search_result_elem(class_object, ontology_acronym, title)
    label = concept_label(class_object.prefLabel)
    {
      uri: class_object.id.to_s,
      title: title.empty? ? label : "#{label} - #{title}",
      ontology_acronym: ontology_acronym,
      link: "/ontologies/#{ontology_acronym}?p=classes&conceptid=#{class_object.id}",
      definition: Array(class_object.definition).join(' ')
    }
  end

  def concept_label(pref_labels_list, obsolete = false, max_length = 60)
    # select closest to query
    selected = pref_labels_list.select do |pref_lab|
      pref_lab.include?(@search_query) || @search_query.include?(pref_lab)
    end.first

    selected ||= (pref_labels_list&.first || '')

    selected = selected[0..max_length] if selected.size > max_length
    selected = "<span class='obsolete_class' title='obsolete class'>#{selected}</span>".html_safe if obsolete
    selected
  end

  def ontology_name_acronym(ontologies, selected_acronym)
    ontology = ontologies.select { |x| x.acronym.eql?(selected_acronym.split('/').last) }.first
    binding.pry if ontology.nil?
    "#{ontology.name} (#{ontology.acronym})"
  end

  def aggregate_by_ontology(results)
    ontologies = {}

    results.each do |res|
      ont = res.links['ontology']
      unless ontologies[ont]
        ontologies[ont] = {
          # classes with same URI
          same_cls: [],
          # other classes from the same ontology
          same_ont: [],
          # subordinate ontologies
          sub_ont: []
        }
      end
      ontologies[ont][:same_ont] << res
    end
    ontologies.values
  end

  def add_subordinate_ontologies(query, ontologies)
    # get for each concept his main ontology parent
    concepts_ontology_owner = extract_concepts_owners(ontologies, query)

    # aggregate the subordinate results below the owner ontology results
    subordinate_ontologies = []
    ontologies.each_with_index do |ont, i|
      cls_id = ont[:same_ont].first["@id"]

      if concepts_ontology_owner.has_key?(cls_id)
        # get the ontology that owns this class (if any)
        ont_owner = concepts_ontology_owner[cls_id]
        if ont_owner[:index].eql?(i)
          # the current ontology is the owner of this primary result
          subordinate_ontologies.push(ont)
        else
          # There is an owner, so put this ont result set into the sub_ont array of the owner
          real_owner = ontologies[ont_owner[:index]]
          real_owner[:sub_ont].push(ont)
        end
      else
        # There is no ontology that owns this primary class result, just
        # display this at the top level (it's not a subordinate)
        subordinate_ontologies.push(ont)
      end
    end
    subordinate_ontologies
  end

  def extract_concepts_owners(ontologies, query)
    cls_ont_owner_tracker = {}
    ontologies.each do |ont|
      ont[:sub_ont] = [] #  array for any subordinate ontology results regrouping the concept reuses

      cls_id = ont[:same_ont].first["@id"]
      next if cls_ont_owner_tracker.has_key?(cls_id)

      # find the best match for the ontology owner (must iterate over all acronyms)
      ont_owner = ontology_owner_of_class(cls_id, ontologies, query)

      # This primary class result is owned by an ontology
      cls_ont_owner_tracker[cls_id] = ont_owner if ont_owner[:index]
    end
    cls_ont_owner_tracker
  end

  def extract_back_list_words(acronyms, query)
    blacklist_words = []
    query.split(/\s+/).each_with_index do |search_word, i|
      # Convert blacklist_search_words_arr to regex constructs so they are removed
      # with case-insensitive matches in blacklist_cls_id_components
      blacklist_words.push(Regexp.new(search_word, Regexp::IGNORECASE))

      # Check for any substring matches against ontology acronyms, where the
      # acronyms are assumed to be upper case strings.
      # Note: We cannot use the ont_acronyms array .index method because it doesn't search for substring matches.
      search_token = search_word
      match = false

      acronyms.each do |acronym|
        match = acronym.include?(search_token)
        break if match
      end

      # Remove this blacklisted search token because it matches or partially matches an ontology acronym.
      blacklist_words.delete_at(i) if match
    end
    blacklist_words
  end

  def ontology_owner_of_class(cls_id, ontologies, query)
    acronyms = ontologies.map { |ont| ont[:same_ont].first.links['ontology'].split('/').last }

    # Remove any items in blacklistSearchWordsArr that match ontology acronyms.
    # TODO make sure this is really useful
    blacklist_words = extract_back_list_words(acronyms, query)

    ont_owner = {
      acronym: "",
      index: nil,
      weight: 0
    }

    acronyms.each_with_index do |acronym, i|
      if ontology_own_class?(cls_id, acronym, blacklist_words)
        weight = acronym.size * (cls_id.upcase.rindex(acronym) + 1)
        if weight > ont_owner[:weight]
          ont_owner = {
            acronym: acronym,
            index: i,
            weight: weight
          }
          # Cannot break here, in case another acronym has greater weight.
        end
      end
    end

    ont_owner
  end

  def ontology_own_class?(cls_id, acronym, blacklist_words)
    cls_id = blacklist_cls_id_components(cls_id.dup, blacklist_words)

    cls_id.upcase.include?(acronym) rescue binding.pry
  end

  def blacklist_cls_id_components(cls_id, blacklist_words)

    stripped_id = cls_id

    # Remove fixed strings first
    BLACKLIST_FIX_STR.each do |fixed_str|
      stripped_id.gsub!(fixed_str, "")
    end

    # Cleanup with regex replacements
    BLACKLIST_REGEX.each do |regex|
      stripped_id.gsub!(regex, "")
    end

    # Remove search keywords (see perform_search and aggregate_results_with_subordinate_ontologies)
    blacklist_words.each do |search_word_regex|
      stripped_id.gsub!(search_word_regex, "")
    end

    stripped_id
  end
end


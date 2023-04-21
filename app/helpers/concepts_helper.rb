# frozen_string_literal: true
module ConceptsHelper
  def exclude_relation?(relation_to_check, ontology = nil)
    excluded_relations = %w[type rdf:type [R] SuperClass InstanceCount]

    # Show or hide property based on the property and ontology settings
    if ontology
      # TODO_REV: Handle obsolete classes
      # Hide owl:deprecated if a user has set class or property based obsolete checking
      # if !ontology.obsoleteParent.nil? && relation_to_check.include?("owl:deprecated") ||
      #    !ontology.obsoleteProperty.nil? && relation_to_check.include?("owl:deprecated")
      #   return true
      # end
    end
    excluded_relations.each do |relation|
      return true if relation_to_check.include?(relation)
    end
    false
  end

  def get_concept_id(params, concept, root)
    if concept_id_param_exist?(params)
      concept.nil? ? '' : concept.id
    elsif !root.children.first.nil?
      root.children.first.id
    end
  end

  def concept_label(ont_id, cls_id)
    @ontology = LinkedData::Client::Models::Ontology.find(ont_id)
    @ontology ||= LinkedData::Client::Models::Ontology.find_by_acronym(ont_id).first
    ontology_not_found(ont_id) unless @ontology
    # Retrieve a class prefLabel or return the class ID (URI)
    # - mappings may contain class URIs that are not in bioportal (e.g. obo-xrefs)
    cls = @ontology.explore.single_class(cls_id)
    # TODO: log any cls.errors
    # TODO: NCBO-402 might be implemented here, but it throws off a lot of ajax result rendering.
    #cls_label = cls.prefLabel({:use_html => true}) || cls_id
    cls.prefLabel || cls_id
  end

  def concept_id_param_exist?(params)
    !(params[:conceptid].nil? || params[:conceptid].empty? || params[:conceptid].eql?("root") ||
      params[:conceptid].eql?("bp_fake_root"))
  end

  def concept_date(concept)
    date = concept.modified || concept.created
    Date.parse(date) if date
  end

  def sorted_by_date_url(page = 1, last_concept = nil)
    out = "/ajax/classes/date_sorted_list?ontology=#{@ontology.acronym}&page=#{page}"
    out += "&last_date=#{concept_date(last_concept)}" if last_concept
    out
  end

  def same_period?(year, month, date)
    return false if date.nil?
    date = Date.parse(date.to_s)
    year.eql?(date.year) && month.eql?(date.strftime('%B'))
  end

  def concepts_li_list(concepts)
    out = ''
    concepts.each do |concept|
      out += tree_link_to_concept(child: concept, ontology_acronym: @ontology.acronym, active_style: '')
    end
    out
  end

  def render_concepts_by_dates
    return if  @concepts_year_month.empty?

    first_year, first_month_concepts = @concepts_year_month.shift
    first_month, first_concepts = first_month_concepts.shift
    out = ''
    if same_period?(first_year, first_month, @last_date)
      out += "<ul>#{concepts_li_list(first_concepts)}</ul>"
    else
      tmp = {}
      tmp[first_month] = first_concepts
      first_month_concepts = tmp.merge(first_month_concepts)
    end
    tmp = {}
    tmp[first_year] = first_month_concepts
    @concepts_year_month = tmp.merge(@concepts_year_month)

    @concepts_year_month.each do |year, month_concepts|
      month_concepts.each do |month, concepts|
        out += "<ul> #{month + ' ' + year.to_s}"
        out += concepts_li_list(concepts)
        out += "</ul>"
      end
    end

    raw out
  end

  def concept_list_url(page = 1, collection_id, acronym)
    "/ajax/classes/list?ontology_id=#{acronym}&collection_id=#{collection_id}&page=#{page}"
  end


  def add_synonym_button
    return unless change_requests_enabled?(@ontology.acronym)

    if session[:user].nil?
      link_to(login_index_path(redirect: concept_redirect_path),
              role: 'button',
              class: 'btn btn-link',
              aria: { label: 'Create synonym' }) do
        content_tag(:i, '', class: 'fas fa-plus-circle fa-lg', aria: { hidden: 'true' }).html_safe
      end
    else
      link_to(change_requests_create_synonym_path(concept_id: @concept.id, concept_label: @concept.prefLabel,
                                                  ont_acronym: @ontology.acronym),
              role: 'button',
              class: 'btn btn-link',
              aria: { label: 'Create synonym' },
              data: { toggle: 'modal', target: '#changeRequestModal' },
              remote: 'true') do
        content_tag(:i, '', class: 'fas fa-plus-circle fa-lg', aria: { hidden: 'true' }).html_safe
      end
    end
  end

  def remove_synonym_button
    return unless change_requests_enabled?(@ontology.acronym)

    if session[:user].nil?
      link_to(login_index_path(redirect: concept_redirect_path),
              role: 'button',
              class: 'btn btn-link',
              aria: { label: 'Remove a synonym' }) do
        content_tag(:i, '', class: 'fas fa-minus-circle fa-lg', aria: { hidden: 'true' }).html_safe
      end
    else
      link_to('#', role: 'button', class: 'btn btn-link', aria: { label: 'Remove a synonym' }) do
        content_tag(:i, '', class: 'fas fa-minus-circle fa-lg', aria: { hidden: 'true' }).html_safe
      end
    end
  end

  def synonym_qualifier_select(form)
    options = [%w[exact exact], %w[narrow narrow], %w[broad broad], %w[related related]]
    form.select :qualifier, options_for_select(options, 0), {}, { class: 'form-control' }
  end

  private

  def concept_redirect_path
    ontology_path(@ontology.acronym, p: 'classes', conceptid: @concept.id)
  end
end
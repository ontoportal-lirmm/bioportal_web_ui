module SubmissionsHelper
  def metadata_help_link
    content_tag(:div, class: 'edit-ontology-desc') do
      html = content_tag(:span, 'To understand the ontologies metadata:')
      html += content_tag(:span, style: 'width: 10px; height: 10px') do
        link_to(render(ExternalLinkTextComponent.new(text: 'see the Wiki')), "https://github.com/agroportal/documentation/wiki/Ontology-metadata")
      end
      html.html_safe
    end
  end


  def ontology_submission_id_label(acronym, submission_id)
    [acronym, submission_id].join('#')
  end

  def submission_metadata_selector(id: 'search_metadata', name: 'search[metadata]', label: 'Filter properties to show')
    select_input(id: id, name: name, label: label, values: submission_editable_properties.sort, multiple: true,
                 data: { placeholder: 'Start typing to select properties' })
  end

  def ontology_and_submission_id(value)
    value.split('#')
  end

  def render_submission_attribute(attribute, submission = @submission, ontology = @ontology)
    render partial: 'ontologies_metadata_curator/attribute_inline_editable', locals: { attribute: attribute, submission: submission, ontology: ontology }
  end

  def attribute_input_frame_id(acronym, submission_id, attribute)
    "submission[#{acronym}_#{submission_id}]#{attribute.capitalize}_from_group_input"
  end

  def edit_submission_property_link(acronym, submission_id, attribute, container_id = nil, &block)
    link = "/ontologies/#{acronym}/submissions/#{submission_id}/edit_properties?properties=#{attribute}&inline_save=true"
    if container_id
      link += "&container_id=#{container_id}"
    else
        link += "&container_id=#{attribute_input_frame_id(acronym, submission_id, attribute)}"
    end
    link_to link, data: { turbo: true }, class: 'btn btn-sm btn-light' do
      capture(&block)
    end
  end

  def display_submission_attributes(acronym, attributes, submissionId: nil, inline_save: false)
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    @selected_attributes = attributes
    @inline_save = inline_save

    if @selected_attributes && !@selected_attributes.empty?
      display_properties = (equivalent_properties(@selected_attributes) + [:ontology, :submissionId]).join(',')
    else
      display_properties = 'all'
    end

    if submissionId
      @submission = @ontology.explore.submissions({ display: display_properties }, submissionId)
    else
      @submission = @ontology.explore.latest_submission({ display: display_properties })
    end
  end

  def inline_save?
    !@inline_save.nil? && @inline_save
  end

  def selected_attribute?(attr)
    return true if @selected_attributes.nil? || @selected_attributes.empty? || @selected_attributes.include?(attr.to_s)
    return true if equivalent_properties(@selected_attributes).include?(attr.to_s)

    equivalent_properties(attr.to_s).any? { |x| @selected_attributes.include?(x) }
  end

  def save_button
    content_tag :div do
      button_tag({ data: { controller: 'tooltip' }, title: 'Save', class: 'btn btn-sm btn-light mx-1' }) do
        content_tag(:i, "", class: 'fas fa-check')
      end
    end

  end

  def cancel_link(acronym: @ontology.acronym, submission_id: @submission.submissionId, attribute:)
    "/ontologies_metadata_curator/#{acronym}/submissions/#{submission_id}/attributes/#{attribute}"
  end

  def cancel_button(href)
    content_tag :div do
      link_to(href, { data: { turbo: true, controller: 'tooltip', turbo_frame: '_self' }, title: 'Cancel', class: 'btn btn-sm btn-light mx-1' }) do
        content_tag(:i, "", class: 'fas fa-times')
      end
    end
  end

  def attribute_form_group_container(attr, &block)
    render(TurboFrameComponent.new(id: "#{object_name}#{attr}_from_group_input")) do
      tag.div(class: 'd-flex w-100 mb-3') do
        html = tag.div(class: 'flex-grow-1 mr-1') do
          capture(&block)
        end

        if inline_save?
          html += tag.div(class: 'd-flex') do
            html = ''
            html += save_button
            html += cancel_button(cancel_link(attribute: attr))
            html.html_safe
          end
        end
        html
      end
    end
  end

  def sections
    [['define-usage', 'Define usage', 'usage'], ['more-methodology-information', 'More methodology information', 'methodology'],
     ['more-links', 'More links', 'links'], ['ontology-images', 'Ontology images', 'images']]
  end

  def format_equivalent
    %w[hasOntologyLanguage prefLabelProperty synonymProperty definitionProperty authorProperty obsoleteProperty obsoleteParent]
  end

  def location_equivalent
    %w[summaryOnly pullLocation uploadFilePath]
  end

  def equivalent_property(attr)
    equivalents = submission_properties

    found = equivalents.select { |x| x.is_a?(Array) && x[0].eql?(attr.to_sym) }
    found.empty? ? attr.to_sym : found.first[1]
  end

  def equivalent_properties(attr_labels)
    labels = Array(attr_labels)
    labels.map { |x| equivalent_property(x) }.flatten
  end

  def submission_properties
    format_equivalents = format_equivalent
    location_equivalents = location_equivalent
    equivalents = location_equivalents + format_equivalents
    out = submission_metadata.map { |x| x['attribute'] }.reject { |x| equivalents.include?(x) }
    out << [:format, format_equivalent]
    out << [:location, location_equivalent]

    out
  end

  def submission_editable_properties
    properties = submission_properties
    properties.map do |x|
      if x.is_a? Array
        [x[0].to_s.underscore.humanize, x[0]]
      else
        [x.to_s.underscore.humanize, x]
      end
    end
  end



  def attribute_infos(attr_label)
    submission_metadata.select{ |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first
  end

  def object_name(acronym = @ontology.acronym, submissionId = @submission.submissionId)
    # TO REMOVE or Update
    'submission'
  end

  def agent_attributes
    submission_metadata.select { |x| x["enforce"].include?('Agent') }.map { |x| x["attribute"] }
  end

  def render_submission_inputs(frame_id)
    output = ""

    if selected_attribute?('acronym')
      output += ontology_acronym_input(update: true)
    end

    if selected_attribute?('name')
      output += ontology_name_input
    end


    if selected_attribute?('hasOntologyLanguage')
      output += render partial: 'submissions/submission_format_form'
    end

    if selected_attribute?('categories')
      output +=  ontology_categories_input
    end

    if selected_attribute?('groups')
      output +=  ontology_groups_input
    end


    if selected_attribute?('administeredBy')
      output += ontology_administered_by_input
    end

    if selected_attribute?('location')
      output += attribute_form_group_container('location') do
        render partial: 'ontologies/submission_location_form'
      end
    end

    if selected_attribute?('contact')
      output += attribute_form_group_container('contact') do
        @submission.contact = [] unless @submission.contact && @submission.contact.size > 0
        contact_input(label: 'Contacts', name: '')
      end
    end

    if selected_attribute?('viewingRestriction')
      output += attribute_form_group_container('viewingRestriction') do
        ontology_visibility_input
      end
    end


    if selected_attribute?('viewOf')
      output += attribute_form_group_container('viewOf') do
        ontology_view_of_input
      end
    end

    reject_metadata = %w[abstract description uploadFilePath contact pullLocation hasOntologyLanguage]
    label = inline_save? ? '' : nil

    if selected_attribute?('abstract')
      output += attribute_form_group_container('abstract') do
        raw attribute_input('abstract',long_text: true, label: label)
      end
    end

    if selected_attribute?('description')
      output += attribute_form_group_container('description') do
        raw attribute_input('description',long_text: true, label: label)
      end
    end

    submission_metadata.reject { |attr| reject_metadata.include?(attr['attribute']) || !selected_attribute?(attr['attribute']) }.each do |attr|
      output += attribute_form_group_container(attr['attribute']) do
        raw attribute_input(attr['attribute'], label: label)
      end
    end




    render TurboFrameComponent.new(id: frame_id) do
      output.html_safe
    end
  end
end
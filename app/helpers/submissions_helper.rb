module SubmissionsHelper
  def metadata_help_link
    content_tag(:div, class: 'edit-ontology-desc') do
      html = content_tag(:div) do
        content_tag(:div, t('submission_inputs.edit_metadata_instruction',
                            portal_name: portal_name,
                            link: link_to(t('submission_inputs.edit_metadata_instruction_link'), Rails.configuration.settings.links[:metadata_help], target: '_blank')).html_safe
        )
      end

      html.html_safe
    end
  end

  def metadata_license_help_link
    content_tag(:div, class: 'edit-ontology-desc') do
      html = content_tag(:div, t('submission_inputs.license_help',
                                 portal_name: portal_name,
                                 link: link_to(t('submission_inputs.license_help_link'), "https://rdflicense.linkeddata.es/", target: '_blank')).html_safe
      )
      html.html_safe
    end
  end

  def metadata_deprecated_help
    content_tag(:div, style: 'edit-ontology-desc') do
      html = content_tag(:div) do
        content_tag(:div, t('submission_inputs.deprecated_help'))
      end
      html.html_safe
    end
  end

  def metadata_knownUsage_help
    content_tag(:div, class: 'edit-ontology-desc') do
      html = content_tag(:div) do
        content_tag(:span, t('submission_inputs.known_usage_help', metadata_knownUsage_help: link_to(t('submission_inputs.known_usage_help_link'), "/projects/new", target: "_blank")).html_safe)
      end
      html.html_safe
    end
  end

  def metadata_help_creator
    content_tag(:div, class: 'edit-ontology-desc') do
      html = content_tag(:div, style: 'text-align: center; margin-top: 56px;') do
        content_tag(:span, t('submission_inputs.help_creator', portal_name: portal_name))
      end

      html.html_safe
    end
  end

  def metadata_version_help
    content_tag(:div, class: 'edit-ontology-desc') do
      content_tag(:div , t('submission_inputs.version_help' , link: link_to(t('submission_inputs.version_helper_link'), "https://hal.science/hal-04094847", target: "_blank")).html_safe).html_safe
    end
  end

  def ontology_submission_id_label(acronym, submission_id)
    [acronym, submission_id].join('#')
  end

  def submission_metadata_selector(id: 'search_metadata', name: 'search[metadata]', label: t('submission_inputs.metadata_selector_label'))
    select_input(id: id, name: name, label: label, values: submission_editable_properties.sort, multiple: true,
                 data: { placeholder: t('submission_inputs.metadata_selector_placeholder') })
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
  def ontology_properties
    ['acronym', 'name', [t('submission_inputs.visibility'), :viewingRestriction], 'viewOf', 'groups', 'categories',
     [t('submission_inputs.administrators'), 'administeredBy']]
  end

  def submission_editable_properties
    properties = submission_properties.map do |x|
      if x.is_a? Array
        [attr_label(x[0], show_tooltip: false), x[0]]
      else
        [attr_label(x, show_tooltip: false), x]
      end
    end

    properties += ontology_properties.map do |x|
      x.is_a?(Array) ? x : [x.to_s.underscore.humanize, x]
    end

  def extractable_metadatum_tooltip(options = {})
    help_tooltip(options[:content], {}, "fas fa-file-export", "extractable-metadatum", options[:text]).html_safe
  end

  def attribute_infos(attr_label)
    @metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first
  end

  def attribute_help_text(attr)
    if !attr["namespace"].nil?
      help_text = "&lt;strong&gt;#{attr["namespace"]}:#{attr["attribute"]}&lt;/strong&gt;"
    else
      help_text = "&lt;strong&gt;bioportal:#{attr["attribute"]}&lt;/strong&gt;"
    end

    if selected_attribute?('name')
      output += ontology_name_input
    end

    if selected_attribute?('hasOntologyLanguage')
      output += has_ontology_language_input
    end

    if selected_attribute?('categories')
      output += ontology_categories_input
    end

    # Generate tooltip
    help_text = attribute_help_text(attr)
    label_html << help_tooltip(help_text, { :id => "tooltip#{attr["attribute"]}" }).html_safe
    label_html
  end

  def object_name(acronym= @ontology.acronym, submissionId= @submission.submissionId)
    "submission[#{acronym}_#{submissionId}]"
  end

  def attribute_input_name(attr_label)
    object_name_val = object_name
    name = "#{object_name_val}[#{attr_label}]"
    [object_name_val, name]
  end

  def generate_integer_input(attr)
    number_field object_name, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]), class: 'metadataInput form-control'
  end

  def generate_date_input(attr)
    field_id = [:submission, attr["attribute"].to_s, @ontology.acronym].join('_')
    date_value = @submission.send(attr["attribute"]).presence
    data_flat_picker = { controller: "flatpickr", flatpickr_date_format: "Y-m-d", flatpickr_alt_input: "true", flatpickr_alt_format: "F j, Y" }
    content_tag(:div, class: 'input-group') do
      [
        date_field(object_name, attr["attribute"].to_s.to_sym, value: date_value, id: field_id, data: data_flat_picker, class: "not-disabled")
      ].join.html_safe
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
      output += metadata_help_creator
    end

  # Generate the HTML input for every attributes.
  def generate_attribute_input(attr_label, options = {})
    input_html = "".html_safe

    # Get the attribute hash corresponding to the given attribute
    attr = @metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first

    object_name, name = attribute_input_name(attr["attribute"])

    if input_type?(attr, 'integer')
      generate_integer_input(attr)
    elsif input_type?(attr, 'date_time')
      generate_date_input(attr)
    elsif input_type?(attr, 'textarea')
      generate_textarea_input(attr)
    elsif enforce_values?(attr)
      metadata_values, select_values = selected_values(attr, enforced_values(attr))
      if input_type?(attr, "list")
        input_html << generate_select_input(attr, name, select_values, metadata_values, multiple: true)
      else
        select_values << ["", ""]
        select_values << %w[Other other]

        metadata_values = "" if metadata_values.nil?

        input_html << generate_select_input(attr, name, select_values, metadata_values)
      end

      return input_html
    elsif input_type?(attr, 'isOntology')
      metadata_values, select_values = selected_values(attr, ontologies_for_select.dup)
      input_html << generate_select_input(attr, name, select_values, metadata_values, multiple: attr["enforce"].include?("list"))
      return input_html
    elsif input_type?(attr, "uri")
      uri_values = attribute_values(attr) || ['']
      if input_type?(attr, "list")
        input_html << generate_url_input(attr, name, uri_values)
      else
        input_html << text_field(object_name, attr["attribute"].to_s.to_sym, value: Array(uri_values).first, class: "metadataInput form-control")
      end
      return input_html
    elsif input_type?(attr, "boolean")
      input_html << generate_boolean_input(attr, name)
    else
      # If input a simple text
      values = attribute_values(attr) || ['']
      if input_type?(attr, "list")
        input_html << generate_list_text_input(attr, name, values)
      else
        # if single value text
        # TODO: For some reason @submission.send("URI") FAILS... I don't know why... so I need to call it manually
        if attr["attribute"].to_s.eql?("URI")
          input_html << text_field(object_name, attr["attribute"].to_s.to_sym, value: @submission.URI, class: "metadataInput form-control")
        else
          input_html << text_field(object_name, attr["attribute"].to_s.to_sym, value: @submission.send(attr["attribute"]), class: "metadataInput form-control")
        end
      end
      input_html
    end
  end

  def generate_attribute_text(attr_label, label)
    attr = attribute_infos(attr_label)
    label_html = "<div class='d-flex align-items-center'><span class='mr-1'>#{label}</span><span>"
    # Generate tooltip
    help_text = attribute_help_text(attr)
    label_html << help_tooltip(help_text, { :id => "tooltip#{attr["attribute"]}" }).html_safe
    label_html << "</span></div>"
    label_html.html_safe
  end

  def ontologies_for_select
    @ontologies_for_select ||= LinkedData::Client::Models::Ontology.all.collect do |onto|
      ["#{onto.name} (#{onto.acronym})", onto.id]
    end
  end

  def form_group_attribute(attr, options = {}, &block)
    attribute_form_group_container(attr, required: !options[:required].nil?) do |c|
      c.label do
        generate_attribute_label(attr)
      end
      c.input do
        raw generate_attribute_input(attr, options)
      end
      if block_given?
        c.help do
          capture(&block)
        end
      end
    end

    if selected_attribute?('viewOf')
      output += attribute_form_group_container('viewOf') do
        ontology_view_of_input
      end
    end

    reject_metadata = %w[abstract description uploadFilePath contact pullLocation hasOntologyLanguage hasLicense bugDatabase knownUsage version notes deprecated status]
    label = inline_save? ? '' : nil

    if selected_attribute?('abstract')
      output += attribute_form_group_container('abstract') do
        raw attribute_input('abstract', long_text: true, label: label)
      end
    end

    if selected_attribute?('description')
      output += attribute_form_group_container('description') do
        raw attribute_input('description', long_text: true, label: label)
      end
    end

    if selected_attribute?('hasLicense')
      output += attribute_form_group_container('hasLicense') do
        raw attribute_input('hasLicense', help: metadata_license_help_link)
      end
    end

    if selected_attribute?('bugDatabase')
      output += attribute_form_group_container('bugDatabase') do
        raw attribute_input('bugDatabase', help: 'Some ontology feedback and notes features are only possible if a GitHub repository is informed.')
      end
    end

    if selected_attribute?('knownUsage')
      output += attribute_form_group_container('knownUsage') do
        raw attribute_input('knownUsage', help: metadata_knownUsage_help)
      end
    end

    if selected_attribute?('version')
      output += attribute_form_group_container('version') do
        raw attribute_input('version', help: metadata_version_help)
      end
    end

    if selected_attribute?('notes')
      output += attribute_form_group_container('notes') do
        raw attribute_input('notes', long_text: true)
      end
    end

    if selected_attribute?('status')
      output += attribute_form_group_container('status') do
        raw attribute_input('status')
      end
    end

    if selected_attribute?('deprecated')
      output += attribute_form_group_container('deprecated') do
        raw attribute_input('deprecated', help: metadata_deprecated_help)
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
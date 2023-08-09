module SubmissionsHelper

  def ontology_submission_id_label(acronym, submission_id)
    [acronym, submission_id].join('#')
  end
  def ontology_and_submission_id(value)
    value.split('#')
  end

  def render_submission_attribute(attribute, submission = @submission, ontology = @ontology)
    render partial: 'ontologies_metadata_curator/attribute_inline_editable', locals: { attribute: attribute, submission: submission, ontology: ontology }
  end

  def render_submission_attribute_inline(attribute, submission = @submission, acronym)
    render partial:"ontologies_metadata_curator/attribute_inline", locals:{attribute: attribute, submission: submission, acronym: acronym}
  end

  def attribute_input_frame_id(acronym, submission_id, attribute)
    "submission[#{acronym}_#{submission_id}]#{attribute.capitalize}_from_group_input"
  end

  def display_submission_attributes(acronym, attributes, submissionId: nil, required: false, show_sections: false, inline_save: false)
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(acronym).first
    @selected_attributes = attributes
    @required_only = required
    @hide_sections = !show_sections
    @inline_save = inline_save

    display_properties = @selected_attributes && !@selected_attributes.empty? ? (equivalent_properties(@selected_attributes) + [:ontology, :submissionId]).join(',') : 'all'
    if submissionId
      @submission = @ontology.explore.submissions({ display: display_properties }, submissionId)
    else
      @submission = @ontology.explore.latest_submission({ display: display_properties })
    end
  end

  def metadata_section(id, label, collapsed: true, parent_id: nil, &block)
    if @hide_sections
      content_tag(:div) do
        capture(&block)
      end
    else
      collapsed = false if !@selected_attributes.nil? || !@errors.nil?
      render CollapsableBlockComponent.new(id: id, parent_id: (parent_id || "#{id}-card"), title: label, collapsed: collapsed) do
        capture(&block)
      end
    end
  end

  def attribute_container(attr, required: false, &block)
    if show_attribute?(attr, required)
    content_tag(:div) do
      capture(&block)
    end
  end
  end

  def inline_save?
    !@inline_save.nil? && @inline_save
  end

  def selected_attribute?(attr)
    @selected_attributes.nil? || @selected_attributes.empty? || @selected_attributes.include?(attr.to_s) || equivalent_properties(@selected_attributes).include?(attr.to_s)
  end

  def show_attribute?(attr, required)
    selected = selected_attribute?(attr)
    required_only = @required_only && required || !@required_only
    selected && required_only
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

  def attribute_form_group_container(attr, label: '', required: false, &block)
    attribute_container(attr, required: required) do
      render FormGroupComponent.new(object: @submission, name: object_name, method: attr, label: label, required: required) do |c|
        if inline_save?
          c.submit do
            html = ''
            html += save_button
            html += cancel_button(cancel_link(attribute: attr))
            html.html_safe
          end
        end

        capture(c, &block)
      end
    end
  end

  def attribute_text_field_container(attr, label: '', required: false, inline: true, &block)
    attribute_container(attr, required: required) do
      render TextFieldComponent.new(object: @submission, name: object_name, label: label, method: attr, required: required, inline: inline) do |c|
        if inline_save?
          c.submit do
            html = ''
            html += save_button
            html += cancel_button(cancel_link(attribute: attr))
            html.html_safe
          end
        end

        capture(c, &block) if block_given?
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
    %w[summaryOnly pullLocation]
  end

  def equivalent_property(attr)
    equivalents = submission_properties

    found = equivalents.select { |x| x.is_a?(Array) && x[0].eql?(attr.to_sym) }
    found.empty? ?  attr.to_sym: found.first[1]
  end

  def equivalent_properties(attr_labels)
    labels = Array(attr_labels)

    labels.map { |x| equivalent_property(x) }.flatten
  end

  def submission_properties
    out = [
      [:format, format_equivalent],
      :version,
      :status,
      [:location, location_equivalent],
      :URI,
      :deprecated,
      :hasOntologySyntax,
      :hasFormalityLevel,
      :isOfType,
      :naturalLanguage,
      :description,
      :homepage,
      :documentation,
      :publication,
      :usedOntologyEngineeringTool,
      :abstract, :notes, :keywords, :alternative, :identifier,
      :knownUsage,
      :designedForOntologyTask,
      :hasDomain,
      :coverage,
      :example,
      :conformsToKnowledgeRepresentationParadigm,
      :usedOntologyEngineeringMethodology,
      :accrualMethod,
      :accrualPeriodicity,
      :accrualPolicy,
      :competencyQuestion,
      :versionIRI,
      :source,
      :isFormatOf,
      :hasFormat,
      :includedInDataCatalog,
      :depiction,
      :logo,
      :associatedMedia,
      :released,
      :modificationDate,
      :valid,
      :curatedOn,
      :publisher,
      :hasLicense,
      :morePermissions,
      :copyrightHolder,
      :contact,
      :hasContributor,
      :hasCreator,
      :audience,
      :toDoList,
      :useGuidelines,
      :repository,
      :bugDatabase,
      :mailingList,
      :award,
      :wasGeneratedBy,
      :wasInvalidatedBy,
      :curatedBy,
      :endorsedBy,
      :fundedBy,
      :translator,
      :useImports,
      :hasPriorVersion,
      :isAlignedTo,
      :ontologyRelatedTo,
      :isBackwardCompatibleWith,
      :isIncompatibleWith,
      :comesFromTheSameDomain,
      :similarTo,
      :explanationEvolution,
      :generalizes,
      :hasDisparateModelling,
      :hasPart,
      :usedBy,
      :workTranslation,
      :translationOfWork,
      :preferredNamespacePrefix,
      :preferredNamespaceUri,
      :keyClasses,
      :endpoint,
      :dataDump,
      :csvDump,
      :openSearchDescription,
      :uriLookupEndpoint,
      :uriRegexPattern,
      :metadataVoc,
      :exampleIdentifier,
      :numberOfClasses,
      :numberOfIndividuals,
      :numberOfProperties,
      :entities,
      :numberOfAxioms
    ]
    out.uniq
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

  def extractable_metadatum_tooltip(options = {})
    help_tooltip(options[:content], {}, 'fas fa-file-export', 'extractable-metadatum', options[:text]).html_safe
  end


  def attribute_infos(attr_label)
    submission_metadata.select{ |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first
  end

  def attribute_help_text(attr)

    if !attr["namespace"].nil?
      help_text = "&lt;strong&gt;#{attr["namespace"]}:#{attr["attribute"]}&lt;/strong&gt;"
    else
      help_text = "&lt;strong&gt;bioportal:#{attr["attribute"]}&lt;/strong&gt;"
    end

    if (attr["metadataMappings"] != nil)
      help_text << " (#{attr["metadataMappings"].join(", ")})"
    end

    if (!attr["enforce"].nil? && attr["enforce"].include?("uri"))
      help_text << "&lt;br&gt;This metadata should be an &lt;strong&gt;URI&lt;/strong&gt;"
    end

    if (attr["helpText"] != nil)
      help_text << "&lt;br&gt;&lt;br&gt;#{attr["helpText"]}"
    end
    help_text
  end

  # Generate the HTML label for every attributes
  def generate_attribute_label(attr_label, label_tag_sym: :label)
    # Get the attribute hash corresponding to the given attribute
    attr = attribute_infos(attr_label)

    return attr_label if attr.nil?
    label_html = ''.html_safe
    # label_html = if !attr["extracted"].nil? && attr["extracted"] == true
    #               extractable_metadatum_tooltip({ content: 'Extractable metadatum' })
    #             end.to_s.html_safe


    label = attr["label"].nil? ? attr_label.underscore.humanize : attr["label"]

    if label_tag_sym.eql? :label
      label_html << label_tag("submission_#{attr_label}", label , { class: 'form-label' })
    else
      label_html << content_tag(label_tag_sym, label, {class: 'form-label'})
    end

    # Generate tooltip
    help_text = attribute_help_text(attr)
    label_html << help_tooltip(help_text, {:id => "tooltip#{attr["attribute"]}"}).html_safe
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

  def generate_agent_input(attr, type: 'person')
    render NestedAgentSearchInputComponent.new(agents: @submission.send(attr["attribute"]), agent_type: type, name_prefix: object_name + "[#{attr['attribute']}]", parent_id: '')
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
  end

  def generate_textarea_input(attr)
    text_area(object_name, attr["attribute"].to_s.to_sym, rows: 3, value: @submission.send(attr["attribute"]), class: 'metadataInput form-control')
  end

  def generate_select_input(attr, name, select_values, metadata_values, multiple: false)
    id = attr["attribute"].to_s + "_" + @ontology.acronym
    render SelectInputComponent.new(id: id, name: name, values: select_values , selected: metadata_values , multiple: multiple)
  end

  def generate_list_field_input(attr, name, values, field_func)
    render NestedFormInputsComponent.new do |c|
      c.template do
        method(field_func).call("#{name}[NEW_RECORD]", '', :id => attr["attribute"].to_s + "_" + @ontology.acronym, class: "metadataInput form-control my-1")
      end

      c.empty_state do
        hidden_field_tag "#{name}[#{values.size}]"
      end

      values.each_with_index do |metadata_val, i|
        c.row do
          method(field_func).call("#{name}[#{i}]", metadata_val, :id => "submission_#{attr["attribute"].to_s}" + "_" + @ontology.acronym, class: "metadataInput my-1 form-control")
        end
      end
    end
  end

  def generate_url_input(attr, name, values)
    generate_list_field_input(attr, name, values, :url_field_tag)
  end

  def generate_list_text_input(attr, name, values)
    generate_list_field_input(attr, name, values, :text_field_tag)
  end

  def generate_boolean_input(attr, name)
    value = attribute_values(attr)
    value = value.to_s unless value.nil?

    render SwitchInputComponent.new(id: name, name:  name, label: "", checked: value.eql?('true') , value: value, boolean_switch: true)
  end

  def input_type?(attr, type)
    attr["enforce"].include?(type)
  end

  def enforce_values?(attr)
    !attr["enforcedValues"].nil?
  end

  def attribute_values(attr)
    begin
      @submission.send(attr["attribute"])
    rescue
      nil
    end
  end

  def agent_attributes
    submission_metadata.select{|x| x["enforce"].include?('Agent')}.map{|x| x["attribute"]}
  end
  # Generate the HTML input for every attributes.
  def generate_attribute_input(attr_label, options = {})
    input_html = ''.html_safe

    # Get the attribute hash corresponding to the given attribute
    attr = submission_metadata.select { |attr_hash| attr_hash["attribute"].to_s.eql?(attr_label) }.first

    object_name, name = attribute_input_name(attr["attribute"])

    if input_type?(attr, 'Agent')
      type = if input_type?(attr, 'is_person')
               'person'
             elsif input_type?(attr, 'is_organization')
               'organization'
             else
               ''
             end
      generate_agent_input(attr, type: type)
    elsif input_type?(attr, 'integer')
      generate_integer_input(attr)
    elsif input_type?(attr, 'date_time')
      generate_date_input(attr)
    elsif input_type?(attr, 'textaclrea')
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


  def generate_attribute_text(attr_label , label, tooltip: true)
    attr = attribute_infos(attr_label)
    label_html = "<div class='d-flex align-items-center'><span class='mr-1'>#{label}</span><span>"
    # Generate tooltip
    if  tooltip
      help_text = attribute_help_text(attr)
      label_html << help_tooltip(help_text, {:id => "tooltip#{attr["attribute"]}"} ).html_safe
    end
    label_html << '</span></div>'
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
  end

  private

  def enforced_values(attr)
    attr["enforcedValues"].collect { |k, v| [v, k] }
  end

  def selected_values(attr, enforced_values)
    metadata_values = attribute_values(attr)
    select_values = enforced_values

    if metadata_values.kind_of?(Array)
      metadata_values.map do |metadata|
        unless select_values.flatten.include?(metadata)
          select_values << metadata
        end
      end
    else
      if !select_values.flatten.include?(metadata_values) && !metadata_values.to_s.empty?
        select_values << metadata_values
      end
    end
    [metadata_values, select_values]
  end

end
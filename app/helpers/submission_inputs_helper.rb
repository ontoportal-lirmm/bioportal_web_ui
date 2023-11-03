module SubmissionInputsHelper

  class SubmissionMetadataInput
    include MetadataHelper

    def initialize(attribute_key:, attr_metadata: , submission: nil, label: nil)
      @attribute_key = attribute_key
      @attr_metadata = attr_metadata
      @submission = submission
      @label = label
    end

    def name
      "submission[#{@attribute_key}]"
    end

    def values
      @submission.send(@attr_metadata['attribute'])
    rescue StandardError
      nil
    end

    def help_text
      CGI.unescape_html(@attr_metadata['helpText']) if @attr_metadata['helpText']
    end

    def label
      @label || @attr_metadata['label'] || @attr_metadata['attribute'].humanize
    end

    def type?(type)
      @attr_metadata['enforce'].include?(type)
    end

    def metadata
      @attr_metadata
    end

    def required?
      Array(@attr_metadata['enforce']).include?('existence')
    end
  end

  # @param attr_key String
  def attribute_input(attr_key, long_text: false, label: nil, show_tooltip: true, max_date: nil)
    attr = SubmissionMetadataInput.new(attribute_key: attr_key, submission: @submission, label: label,
                                       attr_metadata: attr_metadata(attr_key))

    if attr.type?('Agent')
      generate_agent_input(attr)
    elsif attr.type?('integer')
      generate_integer_input(attr)
    elsif attr.type?('date_time')
      generate_date_input(attr, max_date: max_date)
    elsif attr.type?('textarea')
      generate_textarea_input(attr)
    elsif enforce_values?(attr)
      if attr.type?('list')
        generate_select_input(attr, multiple: true)
      else
        generate_select_input(attr)
      end
    elsif attr.type?('isOntology')
      generate_select_input(attr, multiple: attr['enforce'].include?('list'))
    elsif attr.type?('uri')
      generate_url_input(attr)
    elsif attr.type?('boolean')
      generate_boolean_input(attr)
    else
      # If input a simple text
      name = attr.name
      label = attr_header_label(attr, show_tooltip: show_tooltip)
      if attr.type?('list')
        generate_list_text_input(attr)
      elsif attr.metadata['attribute'].to_s.eql?('URI')
        url_input(name: name, label: label, value: @submission.URI)
      elsif long_text
        text_area_input(name: name, label: label,
                        value: attr.values)
      else
        text_input(name: name, label: label,
                   value: attr.values)
      end
    end

  end


  def ontology_name_input(ontology = @ontology)
    text_input(name: 'ontology[name]', value: ontology.name)
  end

  def ontology_acronym_input(ontology = @ontology, update: @is_update_ontology)
    out = text_input(name: 'ontology[acronym]', value: ontology.acronym, disabled: update)
    out += hidden_field_tag('ontology[acronym]', ontology.acronym) if update
    out
  end

  def ontology_administered_by_input(ontology = @ontology, users_list = @user_select_list)
    unless users_list
      users_list = LinkedData::Client::Models::User.all(include: "username").map { |u| [u.username, u.id] }
      users_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
    end
    select_input(label: "Administrator", name: "ontology[administeredBy]", values: users_list, selected: ontology.administeredBy || session[:user].id, multiple: true)
  end

  def ontology_categories_input(ontology = @ontology, categories = @categories)
    categories ||= LinkedData::Client::Models::Category.all(display_links: false, display_context: false)

    render Input::InputFieldComponent.new(name: '', label: 'Categories') do
      content_tag(:div, class: 'upload-ontology-chips-container') do
        hidden_field_tag('ontology[hasDomain][]') +
          categories.map do |category|
            check_input(name: "ontology[hasDomain][]", id: category[:acronym], label: category[:acronym], value: category[:id], checked: ontology.hasDomain&.any? { |x| x.eql?(category[:id]) })
          end.join.html_safe
      end
    end
  end

  def ontology_groups_input(ontology = @ontology, groups = @groups)
    groups ||=  LinkedData::Client::Models::Group.all(display_links: false, display_context: false)

    render Input::InputFieldComponent.new(name: '', label: 'Groups') do
      content_tag(:div, class: 'upload-ontology-chips-container') do
        hidden_field_tag('ontology[group][]') +
          groups.map do |group|
            check_input(name: "ontology[group][]", id: group[:acronym], label: group[:acronym], value: group[:id], checked: ontology.group&.any? { |x| x.eql?(group[:id]) })
          end.join.html_safe
      end
    end
  end

  def ontology_visibility_input(ontology = @ontology)
    unless @user_select_list
      @user_select_list = LinkedData::Client::Models::User.all(include: "username").map { |u| [u.username, u.id] }
      @user_select_list.sort! { |a, b| a[1].downcase <=> b[1].downcase }
    end

    render(Layout::RevealComponent.new(init_show: ontology.viewingRestriction&.eql?('private'), show_condition: 'private')) do |c|
      c.button do
        select_input(label: "Visibility", name: "ontology[viewingRestriction]", values: %w[public private], selected: ontology.viewingRestriction )
      end
      content_tag(:div, class: 'upload-ontology-input-field-container') do
        select_input(label: "Add or remove accounts that are allowed to view classes in this ontology using the account name", name: "ontology[acl]", values: @user_select_list, selected: ontology.acl, multiple: true)
      end
    end
  end

  def ontology_view_of_input(ontology = @ontology)
    render Layout::RevealComponent.new(init_show: ontology.view?) do |c|
      c.button do
        content_tag(:span, class: 'd-flex') do
          switch_input(id: 'ontology_isView', name: 'ontology[isView]', label: 'Is a view of another ontology?', checked: ontology.view?)
        end
      end

      content_tag(:div) do
        render partial: "shared/ontology_picker_single", locals: {placeholder: "", field_name: "viewOf", selected: ontology.viewOf}
      end
    end
  end

  def contact_input(label: '', name: 'Contact', show_help: true)
    attr = SubmissionMetadataInput.new(attribute_key: 'contact', attr_metadata: attr_metadata('contact'))
    render Input::InputFieldComponent.new(name: '', label: attr_header_label(attr, label, show_tooltip: show_help),
                                          error_message: attribute_error(:contact)) do
      render NestedFormInputsComponent.new(object_name: 'Contact', default_empty_row: true) do |c|
        c.header do
          content_tag(:div, "#{name} name", class: 'w-50') + content_tag(:div, "#{name} email", class: 'w-50')
        end

        c.template do
          content_tag(:div, class: 'd-flex my-1') do
            out = content_tag(:div, class: ' w-50 mr-2') do
              text_input(label: '', name: 'submission[contact][NEW_RECORD][name]', value: '', error_message: '')
            end
            out + content_tag(:div, class: ' w-50') do
              text_input(label: '', name: 'submission[contact][NEW_RECORD][email]', value: '', error_message: '')
            end
          end
        end

        Array(@submission.contact).each_with_index do |contact, i|
          c.row do
            content_tag(:div, class: 'd-flex my-1') do
              out = content_tag(:div, class: 'w-50 mr-2') do
                text_input(label: '', name: "submission[contact][#{i}][name]", value: contact['name'], error_message: '')
              end
              out + content_tag(:div, class: 'w-50') do
                text_input(label: '', name: "submission[contact][#{i}][email]", value: contact['email'], error_message: '')
              end
            end
          end
        end
      end
    end
  end

  # @param attr_key string
  def attr_label(attr_key, label = nil, attr_metadata: nil, show_tooltip: true)

    data = SubmissionMetadataInput.new(attribute_key: attr_key.to_s, attr_metadata: attr_metadata)
    if show_tooltip
      attr_header_label(data, label, show_tooltip: show_tooltip)
    else
      label || data.label
    end
  end

  private

  def agent_type(attr)
    if input_type?(attr, 'is_person')
      'person'
    elsif input_type?(attr, 'is_organization')
      'organization'
    else
      ''
    end
  end

  def generate_integer_input(attr)
    # TODO to update to use a component
    number_field object_name, attr.metadata['attribute'].to_s.to_sym, value: @submission.send(attr.metadata['attribute']), class: 'metadataInput form-control'
  end

  def generate_agent_input(attr)
    render Input::InputFieldComponent.new(name: '', error_message: attribute_error(attr.metadata['attribute'])) do
      render NestedAgentSearchInputComponent.new(label: attr_header_label(attr),
                                                 agents: attr.values,
                                                 agent_type: agent_type(attr.metadata),
                                                 name_prefix: attr.name,
                                                 parent_id: '')
    end

  end

  def generate_date_input(attr, max_date: nil)
    date_input(label: attr_header_label(attr), name: attr.name,
               value: attr.values,
               max_date: max_date)
  end

  def generate_textarea_input(attr)
    text_input(name: attr.name,
               value: attr.values)
  end

  def generate_select_input(attr, multiple: false)
    name = attr.name
    label = attr_header_label(attr)
    metadata_values, select_values = selected_values(attr, enforced_values(attr))

    unless multiple
      select_values << ['', '']
      metadata_values = '' if metadata_values.nil? && !attr.required?
    end

    select_input(name: name, label: label, values: select_values,
                 selected: metadata_values, multiple: multiple)
  end

  def generate_list_field_input(attr, name, label, values, &block)
    render Input::InputFieldComponent.new(name: '', error_message: attribute_error(attr.metadata['attribute'])) do
      render NestedFormInputsComponent.new do |c|
        c.header do
          label
        end
        c.template do
          block.call('', "#{name}[NEW_RECORD]", attr.metadata['attribute'].to_s + '_' + @ontology.acronym)
        end

        c.empty_state do
          hidden_field_tag "#{name}[#{Array(values).size}]"
        end

        Array(values).each_with_index do |metadata_val, i|
          c.row do
            block.call(metadata_val, "#{name}[#{i}]", "submission_#{attr.metadata['attribute'].to_s}" + '_' + @ontology.acronym)
          end
        end
      end
    end

  end

  def generate_url_input(attr)
    label = attr_header_label(attr)
    values = attr.values
    name = attr.name
    if attr.type?('list')
      generate_list_field_input(attr, name, label, values) do |value, row_name, id|
        url_input(label: '', name: row_name, value: value)
      end
    else
      url_input(label: label, name: name, value: values)
    end
  end

  def generate_list_text_input(attr)
    label = attr_header_label(attr)
    values = attr.values || ['']
    name = attr.name
    generate_list_field_input(attr, name, label, values) do |value, row_name, id|
      text_input(label: '', name: row_name, value: value)
    end
  end

  def generate_boolean_input(attr)
    value = attr.values
    value = value.to_s unless value.nil?
    name = attr.name
    content_tag(:div, class: 'd-flex') do
      switch_input(id: name, name: name, label: attr_header_label(attr), checked: value.eql?('true'), value: value, boolean_switch: true)
    end
  end

  def enforce_values?(attr)
    !attr.metadata['enforcedValues'].nil?
  end

  def enforced_values(attr)
    attr.metadata['enforcedValues'].collect { |k, v| [v || k, k] }
  end

  def selected_values(attr, enforced_values)
    metadata_values = attr.values
    select_values = enforced_values

    if metadata_values.kind_of?(Array)
      metadata_values.map do |metadata|
        select_values << metadata unless select_values.flatten.include?(metadata)
      end
    elsif !select_values.flatten.include?(metadata_values) && !metadata_values.to_s.empty?
      select_values << metadata_values
    end
    [metadata_values, select_values]
  end

  private

  def attr_header_label(attr, label = nil, show_tooltip: true)
    label ||= attr.label
    return '' if label.nil? || label.empty?

    content_tag(:div) do
      tooltip_span = render(Display::InfoTooltipComponent.new(text: attribute_help_text(attr)))
      html = content_tag(:span, label)
      html += content_tag(:span, '*', class: "text-danger") if attr.required?
      html += content_tag(:span, tooltip_span, class: 'ml-1') if show_tooltip
      html
    end
  end

  def attribute_help_text(attr)
    label = attr.label
    help = attr.help_text
    required = attr.required?
    attr = attr.metadata
    attribute = !attr['namespace'].nil? ? "#{attr['namespace']}:#{attr['attribute']}" : "bioportal:#{attr['attribute']}"

    title = content_tag(:span, "#{label} (#{attribute})")
    title += content_tag(:span, 'required', class: 'badge badge-danger mx-1') if required

    render SummarySectionComponent.new(title: title, show_card: false) do
      help_text = ''
      unless attr['metadataMappings'].nil?
        help_text += render(FieldContainerComponent.new(label: 'Equivalents', value: attr['metadataMappings'].join(', ')))
      end

      unless attr['enforce'].nil? || attr['enforce'].empty?
        help_text += render(FieldContainerComponent.new(label: 'Validators', value: attr['enforce'].map do  |x| 
          content_tag(:span, x.humanize, class: 'badge badge-primary mx-1')
        end.join.html_safe))
      end

      unless attr['helpText'].nil?
        help_text += render(FieldContainerComponent.new(label: 'Help text ', value: help.html_safe))
      end

      help_text
    end
  end
end
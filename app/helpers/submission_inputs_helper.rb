module SubmissionInputsHelper

  class SubmissionMetadataInput
    include MetadataHelper

    def initialize(attribute_key:, submission:, attr_metadata: nil, show_help: true, label: nil)
      @attribute_key = attribute_key
      @attr_metadata = attr_metadata || attr_metadata(attribute_key)
      @submission = submission
      @show_help = show_help
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
      CGI.unescape_html(@attr_metadata['helpText']) if @attr_metadata['helpText'] && show_help?
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

    private

    def show_help?
      @show_help
    end
  end

  # @param attr_key String
  def attribute_input(attr_key, attr_metadata: nil, show_help: true, long_text: false, label: nil)
    attr = SubmissionMetadataInput.new(attribute_key: attr_key, show_help: false, submission: @submission, label: label, attr_metadata: attr_metadata)

    if attr.type?('Agent')
      generate_agent_input(attr)
    elsif attr.type?('integer')
      generate_integer_input(attr)
    elsif attr.type?('date_time')
      generate_date_input(attr)
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
      label = attr.label
      if attr.type?('list')
        generate_list_text_input(attr)
      elsif attr.metadata['attribute'].to_s.eql?('URI')
        url_input(name: name, label: label, value: @submission.URI, help: attr.help_text)
      elsif long_text
        text_area_input(name: name, label: label,
                        value: attr.values, help: attr.help_text)
      else
        text_input(name: name, label: label,
                   value: attr.values, help: attr.help_text)
      end
    end

  end

  def contact_input
    render Input::InputFieldComponent.new(name: '', error_message: attribute_error(:contact),
                                          helper_text: attr_metadata('contact')['helpText']) do
      render NestedFormInputsComponent.new(object_name: 'Contact') do |c|
        c.header do
          content_tag(:div, 'Contact name', class: 'w-50') + content_tag(:div, 'Contact email', class: 'w-50')
        end

        c.template do
          content_tag(:div, class: 'd-flex my-1') do
            out = content_tag(:div, class: ' w-50 mr-2') do
              text_input(label: '', name: 'submission[contact][NEW_RECORD][name]', value: '')
            end
            out + content_tag(:div, class: ' w-50') do
              text_input(label: '', name: 'submission[contact][NEW_RECORD][email]', value: '')
            end
          end
        end

        Array(@submission.contact).each_with_index do |contact, i|
          c.row do
            content_tag(:div, class: 'd-flex my-1') do
              out = content_tag(:div, class: 'w-50 mr-2') do
                text_input(label: '', name: "submission[contact][#{i}][name]", value: contact['name'])
              end
              out + content_tag(:div, class: 'w-50') do
                text_input(label: '', name: "submission[contact][#{i}][email]", value: contact['email'])
              end
            end
          end
        end
      end
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
    render Input::InputFieldComponent.new(name: '', error_message: attribute_error(attr.metadata),
                                          helper_text: attr.help_text) do
      render NestedAgentSearchInputComponent.new(label: attr.label,
                                                 agents: attr.values,
                                                 agent_type: agent_type(attr.metadata),
                                                 name_prefix: attr.name,
                                                 parent_id: '')
    end

  end

  def generate_date_input(attr)
    date_input(label: attr.label, name: attr.name,
               value: attr.values || Date.today,
               help: attr.help_text)
  end

  def generate_textarea_input(attr)
    text_input(name: attr.name,
               value: attr.values,
               help: attr.help_text)
  end

  def generate_select_input(attr, multiple: false)
    name = attr.name
    label = attr.label
    metadata_values, select_values = selected_values(attr, enforced_values(attr))

    unless multiple
      select_values << ['', '']
      metadata_values = '' if metadata_values.nil?
    end

    select_input(name: name, label: label, values: select_values,
                 selected: metadata_values, multiple: multiple,
                 help: attr.help_text)
  end

  def generate_list_field_input(attr, name, label, values, &block)
    render Input::InputFieldComponent.new(name: '', error_message: attribute_error(attr.metadata),
                                          helper_text: attr.help_text) do
      render NestedFormInputsComponent.new do |c|
        c.header do
          content_tag(:div, label)
        end
        c.template do
          block.call('', "#{name}[NEW_RECORD]", attr.metadata['attribute'].to_s + '_' + @ontology.acronym)
        end

        c.empty_state do
          hidden_field_tag "#{name}[#{values.size}]"
        end

        values.each_with_index do |metadata_val, i|
          c.row do
            block.call(metadata_val, "#{name}[#{i}]", "submission_#{attr.metadata["attribute"].to_s}" + '_' + @ontology.acronym)
          end
        end
      end
    end

  end

  def generate_url_input(attr)
    label = attr.label
    values = attr.values
    name = attr.name
    if attr.type?('list')
      generate_list_field_input(attr, name, label, values || ['']) do |value, row_name, id|
        url_input(label: '', name: row_name, value: value)
      end
    else
      url_input(label: label, name: name, value: values, help: attr.help_text)
    end
  end

  def generate_list_text_input(attr)
    label = attr.label
    values = attr.values || ['']
    name = attr.name
    help = attr.help_text
    generate_list_field_input(attr, name, label, values) do |value, row_name, id|
      text_input(label: '', name: row_name, value: value)
    end
  end

  def generate_boolean_input(attr)
    value = attr.values
    value = value.to_s unless value.nil?
    name = attr.name
    content_tag(:div, class: 'd-flex') do
      switch_input(id: name, name: name, label: attr.label, checked: value.eql?('true'), value: value, boolean_switch: true)
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
        unless select_values.flatten.include?(metadata)
          select_values << metadata
        end
      end
    elsif !select_values.flatten.include?(metadata_values) && !metadata_values.to_s.empty?
      select_values << metadata_values
    end
    [metadata_values, select_values]
  end

end
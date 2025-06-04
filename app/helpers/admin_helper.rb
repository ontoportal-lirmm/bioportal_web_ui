module AdminHelper
  def selected_admin_section?(section_title)
    current_section = params[:section] || 'site'
    current_section.eql?(section_title)
  end


  def new_ontologies_created_title
    content_tag(:div,
                t('admin.new_ontologies_created_title', count: @new_ontologies_count.join(', ')),
                style: 'width: 400px; max-height: 300px')
  end

  def visits_evolution
    return 0 if @users_visits[:visits].empty?

    @users_visits[:visits].last - @users_visits[:visits][-2]
  end

  def action_button(name, link, method: :post, class_style: 'btn btn-link')
    button_to name, link, method: method, class: class_style,
                form: {data: { turbo: true, turbo_confirm: t('admin.turbo_confirm', name: name), turbo_frame: '_top'}}

  end

  def attr_metadata_header_label(attr, label = nil, show_tooltip: true)
    label ||= attr.label
    return '' if label.nil? || label.empty?

    content_tag(:div) do
      tooltip_span = render(Display::InfoTooltipComponent.new(text: attribute_metdata_help_text(attr)))
      html = content_tag(:span, label)
      html += content_tag(:span, '*', class: "text-danger") if attr.required?
      html += content_tag(:span, tooltip_span, class: 'ml-1') if show_tooltip
      html
    end
  end

  private

  def attribute_metdata_help_text(attr)
    label = attr.label
    help = attr.helpText
    required = attr.required?
    attribute = !attr.namespace.nil? ? "#{attr.namespace}:#{attr.attribute}" : "bioportal:#{attr.attribute}"

    title = content_tag(:span, "#{label} (#{attribute})")
    title += content_tag(:span, 'required', class: 'badge badge-danger mx-1') if required

    render SummarySectionComponent.new(title: title, show_card: false) do
      help_text = ''
      unless attr.metadataMappings.nil?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.equivalents'), value: attr.metadataMappings.join(', ')))
      end

      unless attr.enforce.nil? || attr.enforce.empty?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.validators'), value: attr.enforce.map do |x|
          content_tag(:span, x.humanize, class: 'badge badge-primary mx-1')
        end.join.html_safe))
      end

      unless attr['helpText'].nil?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.help_text'), value: help.html_safe))
      end

      help_text
    end
  end

end

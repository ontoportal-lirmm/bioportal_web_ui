module ComponentsHelper
  def info_tooltip(text)
    render Display::InfoTooltipComponent.new(text: text)
  end

  def empty_state_message(message)
    content_tag(:p, message.html_safe, class: 'font-italic field-description_text')
  end

  def properties_list_component(c, properties, &block)
    properties.each do |k, value|
      values, label = value
      c.row do
        content = if block_given?
                    capture(values, &block)
                  else
                    if link?(Array(values).first)
                      horizontal_list_container(values) { |v| link?(v) ? render(LinkFieldComponent.new(value: v)) : v }
                    else
                      Array(values).join(', ')
                    end
                  end
        render FieldContainerComponent.new(label: attr_label(k, label, attr_metadata: attr_metadata(k.to_s), show_tooltip: false), value: content.to_s.html_safe)
      end
    end

  end


  def horizontal_list_container(values, &block)
    return if Array(values).empty?

    render Layout::HorizontalListComponent.new do |l|
      Array(values).each do |v|
        l.element do
          capture(v, &block)
        end
      end
    end
  end

  def list_container(values, &block)
    return if Array(values).empty?

    render Layout::ListComponent.new do |l|
      Array(values).each do |v|
        l.row do
          capture(v, &block)
        end
      end
    end
  end

  def properties_card(title, tooltip, properties, &block)
    render Layout::CardComponent.new do |d|
      d.header(text: title, tooltip: tooltip)
      render(Layout::ListComponent.new) do |c|
        if properties
          properties_list_component(c, properties, &block)
        else
          capture(c, &block)
        end
      end
    end
  end

  def properties_dropdown(id, title, tooltip, properties, &block)
    render DropdownContainerComponent.new(title: title, id: id, tooltip: tooltip) do |d|
      d.empty_state do
        properties_string = properties.keys[0..4].map { |key| "<b>#{attr_label(key, attr_metadata: attr_metadata(key), show_tooltip: false)}</b>" }.join(', ') + '... ' if properties
        empty_state_message "The fields #{properties_string} are empty"
      end

      render Layout::ListComponent.new do |c|
        if properties
          properties_list_component(c, properties, &block)
        else
          capture(c, &block)
        end
      end
    end
  end

  def form_save_button
    render Buttons::RegularButtonComponent.new(id:'save-button', value: "Save", variant: "primary", size: "slim", type: "submit") do |btn|
      btn.icon_left do
        inline_svg_tag "check.svg"
      end
    end
  end

  def form_cancel_button
    render Buttons::RegularButtonComponent.new(id:'cancel-button', value: "Cancel", variant: "secondary", size: "slim") do |btn|
      btn.icon_left do
         inline_svg_tag "x.svg", width: "20", height: "20"

      end
    end
  end


end

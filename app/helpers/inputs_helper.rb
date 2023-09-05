module InputsHelper

  def text_input(name:, value:, label: nil, disabled: false, help: nil)
    render Input::TextInputComponent.new(label: input_label(label, name), name: name, value: value,
                                         error_message: input_error_message(name),
                                         disabled: disabled,
                                         helper_text: help)
  end

  def select_input(name:, values:, id: nil, label: nil, selected: nil, multiple: false, help: nil, data: {})
    render Input::SelectComponent.new(label: input_label(label, name), id: id, name: name, value: values,
                                      selected: selected,
                                      multiple: multiple,
                                      helper_text: help, data: data)
  end

  def check_input(id:, name:, value:, label: '', checked: false)
    render ChipsComponent.new(name: name, id: id, label: label, value: value, checked: checked)
  end

  def switch_input(id:, name:, label:, checked: false, value: '', boolean_switch: false)
    render SwitchInputComponent.new(id: id, name: name, label: label, checked: checked, value: value, boolean_switch: boolean_switch)
  end

  def url_input(name:, value:, label: nil, help: nil)
    render Input::UrlComponent.new(label: input_label(label, name), name: name, value: value,
                                   error_message: input_error_message(name),
                                   helper_text:  help)
  end

  def text_area_input(name:, value:, label: nil, help: nil)
    render Input::TextAreaComponent.new(label: input_label(label, name), name: name, value: value,
                                        error_message: input_error_message(name),
                                        helper_text: help)
  end

  def date_input(name:, value:, label: nil, help: nil)
    render Input::DateComponent.new(label: input_label(label, name), name: name, value: value,
                                    error_message: input_error_message(name),
                                    helper_text: help)
  end

  private

  def method_name(name)
    match = /.*\[(.*?)\]/.match(name)
    match.nil? ? name : match[1]
  end

  def input_label(label, name)
    label || method_name(name).humanize
  end

  def attribute_error(attr)
    return '' unless @errors && @errors[attr.to_sym]

    errors = @errors[attr.to_sym]

    errors.values.join(', ')
  end

  def input_error_message(name)
    attribute_error(method_name(name))
  end
end
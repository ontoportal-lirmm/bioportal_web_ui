module InputsHelper

  def text_input(label: nil,  name: , value:, disabled: false)
    render Input::TextInputComponent.new(label: input_label(label, name) , name: name, value: value, error_message: input_error_message(name), disabled: disabled)
  end

  def select_input(label: nil,  name: , values:, selected: nil, multiple: false)
    render Input::SelectComponent.new(label: input_label(label, name), name: name, value: values, selected: selected, multiple: multiple)
  end

  def check_input(id:, name: , label: '',  value:, checked: false)
    render ChipsComponent.new(name: name, id: id, label: label, value: value, checked: checked)
  end

  def switch_input(id: , name:, label: ,checked: false)
    render SwitchInputComponent.new(id: id, name:  name, label:  label, checked: checked)
  end

  def url_input(label: nil,  name: , value:)
    render Input::UrlComponent.new(label: input_label(label, name), name: name, value: value, error_message:  input_error_message(name) )
  end

  def text_area_input(label: nil,  name: , value:)
    render Input::TextAreaComponent.new(label: input_label(label, name), name: name, value: value, error_message: input_error_message(name))
  end

  def date_input(label: nil, name:, value:)
    render Input::DateComponent.new(label: input_label(label, name) ,name: name, value: value || Date.today, error_message: input_error_message(name))
  end

  private

  def method_name(name)
    match = /.*\[(.*?)\]/.match(name)
    match.nil? ? name : match[1]
  end

  def input_label(label, name)
    label || method_name(name).humanize
  end

  def input_error_message(name)
    attribute_error(method_name(name))
  end
end
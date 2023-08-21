class Buttons::RegularButtonComponent < ViewComponent::Base
  renders_one :icon_left
  renders_one :icon_right

  def initialize(id: "", value:, variant: "primary", color: "normal", href: "", size: "normal", state: "animate")
    @id = id
    @value = value
    @variant = variant
    @color = color
    @href = href
    @size = size
    @state = state
  end

  def button_label
    content_tag(:span, icon_left, class: "#{@variant}-button-icon left-button-icon") + @value + content_tag(:span, icon_right, class: "#{@variant}-button-icon right-button-icon")
  end

  def button_elem
    slim_class = @size == "slim" ? "slim " : " "
    danger_class = @color == "danger" ? "danger-button " : " "
    warning_class = @color == "warning" ? "warning-button " : " "
    disabled_class = @state == "disabled" ? "disabled-button " : " "
    class_style = "#{@variant}-button regular-button " + danger_class + warning_class + disabled_class + slim_class
    if link?
      link_to(@href, class: class_style, onclick: "displayAnimation()", id: @id) do
        button_label
      end
    else
      button_tag(type: 'submit', class: class_style, onclick: "displayAnimation()", id: @id) do
        button_label
      end
    end
  end

  def link?
    @href && !@href.empty?
  end

  def load_animation?
    @state == "animate"
  end

end

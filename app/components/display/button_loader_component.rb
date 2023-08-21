# frozen_string_literal: true

class Display::ButtonLoaderComponent < ViewComponent::Base

  def initialize(id: nil, slim: false, color: 'normal')
    @slim = slim
    @color = color
    @id = id
  end


  def call
    slim_class = @size == "slim" ? "slim " : ""
    danger_class = @color == "danger" ? "danger-button " : ""
    warning_class = @color == "warning" ? "warning-button " : ""

    content_tag(:div, class: "animation-container #{danger_class} #{warning_class} #{slim_class}", id: @id) do
      content_tag(:div, class: "lds-ellipsis") do
        4.times.map { content_tag(:div) }.join.html_safe
      end
    end
  end
end

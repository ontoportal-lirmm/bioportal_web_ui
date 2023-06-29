class NestedFormInputComponentPreview < ViewComponent::Preview

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper

  # @param object_name text
  def default(object_name: 'contact')
    render NestedFormInputsComponent.new(object_name: object_name) do |c|
      c.header do
        content_tag(:div, 'Contact name', class: 'w-50 mx-1') + content_tag(:div, 'Contact email', class: 'w-50 mx-1')
      end

      c.template do
        raw "<div class='d-flex'> <input class='form-control w-50 mx-1'/> <input class='form-control w-50 mx-1'/></div>".html_safe
      end
    end
  end

  private

  def long_text
    "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  end
end
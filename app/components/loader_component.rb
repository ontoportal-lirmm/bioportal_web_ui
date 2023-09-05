# frozen_string_literal: true

class LoaderComponent < ViewComponent::Base
  include ActionView::Helpers::TagHelper

  def call
    content_tag(:div, class: 'd-flex align-items-center flex-column') do
      content_tag(:div, class:'spinner-border') do
        content_tag(:span) do
          'Loading'
        end
        content_tag(:div, class: 'spinner-text my-2') do
          'Loading'
        end
      end
    end
  end

  def small?
    @small
  end
  def small_class
    "spinner-border-sm"
  end

end

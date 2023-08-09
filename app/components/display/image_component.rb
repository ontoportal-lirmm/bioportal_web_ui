# frozen_string_literal: true

class Display::ImageComponent < ViewComponent::Base
  include ModalHelper

  def initialize(src: )
    super
    @src = src
  end

  def call
    content_tag(:div, class: 'image-container ') do
      depiction_with_modal(@src)
    end
  end

  def depiction_with_modal(depiction_url)
    img_tag = image_tag(depiction_url, class: 'image-content')
    loop_icon_tag = content_tag(:span , image_tag('summary/loop.svg'), class: 'loop_icon')
    modal_url = "/ajax/submission/show_depiction?depiction_url=#{depiction_url}"
    modal_options = { data: { show_modal_title_value: 'Depiction', show_modal_size_value: 'modal-xl' } }

    link_to_modal(loop_icon_tag + img_tag, modal_url, modal_options)
  end
end

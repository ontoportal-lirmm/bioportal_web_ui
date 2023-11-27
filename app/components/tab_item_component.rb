# frozen_string_literal: true

class TabItemComponent < ViewComponent::Base

  include ActionView::Helpers::UrlHelper

  def initialize(id: nil, title: nil, path: nil, page_name: '', selected: false)
    super
    @id = id
    @title = title
    @path = path
    @page_name = page_name
    @selected = selected
  end

  def selected_item?
    @selected
  end

  def item_id
    id.parameterize.underscore
  end

  def target_id
    "#{item_id}_content"
  end


  def id
    @id || @title
  end

  def title
    @title&.humanize
  end

  def active_class
    selected_item? ? 'active show' : ''
  end

  def page_name
    @page_name
  end

  def call
    if title && !title.empty?
      link_to(title, @path, id: "#{item_id}_tab", class: "#{active_class} tab-link")
    else
      link_to(@path, id: "#{item_id}_tab", class: "#{active_class} tab-link") do
        content
      end
    end
  end

end

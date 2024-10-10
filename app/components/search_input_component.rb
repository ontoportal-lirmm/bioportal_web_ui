# frozen_string_literal: true

class SearchInputComponent < ViewComponent::Base

  renders_one :template

  def initialize(id: '',
                 name: '', placeholder: '', actions_links: {},
                 scroll_down: true, use_cache: true,
                 ajax_url:,
                 item_base_url:,
                 id_key:,
                 links_target: '_top',
                 search_icon_type: nil,
                 display_all: false)
    @id = id
    @name = name
    @placeholder = placeholder
    @actions_links = actions_links
    @use_cache = use_cache
    @scroll_down = scroll_down
    @ajax_url = ajax_url
    @item_base_url = item_base_url
    @id_key = id_key
    @links_target = links_target
    @search_icon_type = search_icon_type
    @display_all = display_all
  end
  def action_link_info(value)
    if value.is_a?(Hash)
       [value[:link] , value[:target]]
    else
      [value, '_top']
    end
  end
  def nav_icon_class
    @search_icon_type.eql?('nav') ? 'search-input-nav-icon' : ''
  end
  def display_all_mode_class
    @display_all ? 'search-container-scroll' : ''
  end
end

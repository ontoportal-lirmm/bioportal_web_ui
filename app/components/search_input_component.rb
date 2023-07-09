# frozen_string_literal: true

class SearchInputComponent < ViewComponent::Base

  renders_one :template

  def initialize(name: '', placeholder:'', actions_links: {}, scroll_down: true, use_cache: true)
    super
    @name = name
    @placeholder = placeholder
    @actions_links = actions_links
    @use_cache = use_cache
    @scroll_down = scroll_down
  end
end

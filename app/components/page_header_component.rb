# frozen_string_literal: true

class PageHeaderComponent < ViewComponent::Base
    renders_many :action_links
  
    def initialize(title: , description:)
      super
      @title = title
      @description = description
    end  
  end
  
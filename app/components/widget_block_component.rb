# frozen_string_literal: true

class WidgetBlockComponent < ViewComponent::Base

  renders_one :help_text
  renders_one :widget

  def initialize(id: , title:  , description:)
    @id = id
    @title = title
    @description  = description
  end
end

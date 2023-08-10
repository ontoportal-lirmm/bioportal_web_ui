# frozen_string_literal: true

class LabelLinkComponent < ViewComponent::Base

  def initialize(id:, text:, icon: 'open-popup')
    @id = id
    @text = text
    @icon = icon
  end

  def call
    if @id.eql?(@text)
      ExternalLinkTextComponent.new(text: @text).call
    else
      InternalLinkTextComponent.new(text: @text).call
    end
  end

  def self.inline(id, text)
    { plain: LabelLinkComponent.new(id: id, text: text).call }
  end
end

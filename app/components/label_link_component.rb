# frozen_string_literal: true

class LabelLinkComponent < ViewComponent::Base

  def initialize(id:, text:, icon: 'fas fa-external-link-alt')
    @id = id
    @text = text
    @icon = icon
  end

  def call
    if @id.eql?(@text)
      @text
    else
      @text + "<i class=' #{@icon} mx-1'></i>"
    end
  end

  def self.inline(id, text)
    { plain: LabelLinkComponent.new(id: id, text: text).call }
  end
end

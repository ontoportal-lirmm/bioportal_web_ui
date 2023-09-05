# frozen_string_literal: true
require 'iso-639'

class LanguageFieldComponent < ViewComponent::Base

  include FlagIconsRails::Rails::ViewHelpers

  def initialize(value:, label: nil)
    super
    @value = value
    @lang_code = ISO_639.find(value.split('/').last)&.alpha2 || nil
    @label = label
  end

  def lang_code
    if @lang_code
      @lang_code = 'gb' if @lang_code.eql?('en')
      @lang_code
    else
      @value
    end
  end
end

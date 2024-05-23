# frozen_string_literal: true

class TextAreaFieldComponent < ViewComponent::Base
  include InternationalisationHelper

  def initialize(value: , see_more_text: t('components.see_more') , see_less_text: t('components.see_less'))
    super
    @value = value
    @see_more_text = see_more_text
    @see_less_text = see_less_text
  end

end

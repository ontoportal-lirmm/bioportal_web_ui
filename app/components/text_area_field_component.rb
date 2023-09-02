# frozen_string_literal: true

class TextAreaFieldComponent < ViewComponent::Base

  def initialize(value: , see_more_text:'See more...' , see_less_text: 'See less...')
    super
    @value = value
    @see_more_text = see_more_text
    @see_less_text = see_less_text
  end

end
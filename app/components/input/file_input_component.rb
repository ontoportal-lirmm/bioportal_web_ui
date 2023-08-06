# frozen_string_literal: true

class Input::FileInputComponent < ViewComponent::Base
  def initialize(name:, html_options: '')
    @name = name
    @html_options = html_options
  end

end

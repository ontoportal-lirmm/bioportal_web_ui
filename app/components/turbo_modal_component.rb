# frozen_string_literal: true

class TurboModalComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(id: '', title:'', size: 'modal-lg')
    super
    @id = id
    @title = title
    @size = size
  end

end

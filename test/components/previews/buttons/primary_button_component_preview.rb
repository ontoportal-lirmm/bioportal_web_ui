# frozen_string_literal: true
class Buttons::PrimaryButtonComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'


  def primary
    def primary()
      render Buttons::PrimaryButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary")
    end
  end

  
  def secondary
    def secondary()
      render Buttons::PrimaryButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "secondary")
    end
  end


end
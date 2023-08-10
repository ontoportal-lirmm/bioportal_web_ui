# frozen_string_literal: true
class Buttons::RegularButtonComponentPreview < ViewComponent::Preview
  layout 'component_preview_not_centred'


  def primary
    def primary()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary")
    end
  end

  
  def secondary
    def secondary()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "secondary")
    end
  end

  def slim
    def slim()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", size: "slim")
    end
  end

  def icon_left
    def icon_left()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", icon: "check.svg")
    end
  end

  def icon_right
    def icon_right()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", icon: "check.svg", icon_type: "right")
    end
  end


end
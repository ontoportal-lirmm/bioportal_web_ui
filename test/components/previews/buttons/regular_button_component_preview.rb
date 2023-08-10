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

  def danger
    def danger()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", color: "danger")
    end
  end

  def warning
    def warning()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", color: "warning")
    end
  end

  def disabled
    def disabled()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", state: "disabled")
    end
  end

  def no_animation
    def no_animation()
      render Buttons::RegularButtonComponent.new(value: "Login", name: "login", type: "regular", variant: "primary", state: "regular")
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
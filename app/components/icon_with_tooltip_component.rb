class IconWithTooltipComponent < ViewComponent::Base
    def initialize(icon: "", link: "#", size: "small", target: '', title: '', style: '')
      @icon = icon
      @link = link
      @size = size
      @target = target
      @title = title
      @style = style
    end
  
    private
  
    def size
      case @size
      when "small"
        ["32px", "1", "16px"]
      when "medium"
        ["45px", "1", "23px"]
      when "big"
        ["100px", "2.5", "50px"]
      end
    end
  
    def icon_with_tooltip_style
      "font-size: 50px; line-height: 0.5; #{@style}"
    end
end
  
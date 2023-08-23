class RoundedButtonComponent < ViewComponent::Base
  def initialize(icon: "json.svg", link: "#", size: "small", target: '')
    @icon = icon
    @link = link
    @size = size
    @target = target
  end

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

end
module Sass::Script::Functions

  def body_margin_bottom
    #margin = Rails.env.appliance? ? "360px" : "320px"
    margin = "250px"
    Sass::Script::String.new(margin)
  end

  declare :body_margin_bottom, []

end
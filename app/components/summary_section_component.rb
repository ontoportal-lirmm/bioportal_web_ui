# frozen_string_literal: true

class SummarySectionComponent < ViewComponent::Base
  renders_many :action_links

  def initialize(title: , link: nil, link_title: nil, show_card:  true, show_icon: false, service_link: nil)
    super
    @title = title
    @link = link
    @link_title = link_title
    @show_card = show_card
    @show_icon = show_icon
    @service_link = service_link
  end

  def show_card?
    @show_card
  end

  def show_icon?
    @show_icon
  end
  
  def link_svg(link)
    link_to(link, target: "_blank", title: 'Go to API') do
      tag.img(src: asset_path('json.svg'), "aria-hidden" => "true", style: "margin-left: 0.5rem; width: 16px; margin-top: 2px;")
    end
  end
 
end

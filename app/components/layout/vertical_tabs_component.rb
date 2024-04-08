# frozen_string_literal: true

class Layout::VerticalTabsComponent < ViewComponent::Base

  renders_many :item_contents

  def initialize(titles: [], header: nil , selected: nil)
    @titles = titles
    @selected = selected
    @header = header
  end

end

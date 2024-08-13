# frozen_string_literal: true

class Layout::ListComponentPreview < ViewComponent::Preview
  def vertical
    render Layout::ListComponent.new do |l|
      4.times.each do |i|
        l.row {content_tag(:div , "element #{i}", class: 'p-1 border')}
      end
    end
  end

  def horizontal
    render Layout::HorizontalListComponent.new do |l|
      4.times.each do |i|
        l.element {content_tag(:div , "element #{i}", class: 'p-1 border')}
      end
    end
  end
end

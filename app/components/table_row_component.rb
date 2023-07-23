# frozen_string_literal: true

class TableRowComponent < ViewComponent::Base

  renders_many :cells, TableCellComponent

  def create(*array, &block)
    array.each do |key_value|
      key, value = key_value.to_a.first
      self.cell(type: key) { value&.to_s }
    end
    block.call(self) if block_given?
  end

  def th(width: nil, &block)
    self.cell(type: 'th', width: width, &block)
  end

  def td(width: nil, &block)
    self.cell(type: 'td', width: width, &block)
  end
end

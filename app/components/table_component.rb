# frozen_string_literal: true

class TableComponent < ViewComponent::Base

  renders_one :header, TableRowComponent
  renders_many :rows, TableRowComponent

  def initialize(id: '', stripped: true, borderless: false, layout_fixed: false )
    super
    @id = id
    @stripped = stripped
    @borderless = borderless
    @layout_fixed = layout_fixed
  end

  def stripped_class
    @stripped ? 'table-content-stripped' : ''
  end

  def borderless_class
    @borderless ? 'table-content-borderless' : ''
  end

  def layout_fixed_class
    @layout_fixed ? 'table-layout-fixed' : ''
  end

  def add_row(*array, &block)
    self.row.create(*array, &block)
  end
end

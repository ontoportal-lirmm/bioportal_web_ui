# frozen_string_literal: true

class TableComponent < ViewComponent::Base

  renders_one :header, TableRowComponent
  renders_many :rows, TableRowComponent

  def initialize(id: '', stripped: true, borderless: false, layout_fixed: false, small_text: false, custom_class: '', outline: false, sort: false, default_sort_column: '0', paging: false, searching: false)
    super
    @id = id
    @stripped = stripped
    @borderless = borderless
    @layout_fixed = layout_fixed
    @small_text = small_text
    @outline = outline
    @sort = sort
    @default_sort_column = default_sort_column
    @paging = paging
    @searching = searching
    @custom_class = custom_class
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

  def mini_class
    @small_text ? 'table-mini' : ''
  end

  def outline_class
    @outline ? 'table-outline' : ''
  end
end

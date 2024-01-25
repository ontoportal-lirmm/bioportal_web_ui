# frozen_string_literal: true

class TableComponent < ViewComponent::Base

  renders_one :header, TableRowComponent
  renders_many :rows, TableRowComponent

  def initialize(id: '', stripped: true, borderless: false, custom_class: '', layout_fixed: false, small_text: false, outline: false, sort: false, default_sort_column: '0', paging: false, searching: false, no_init_sort: false, auto_layout: false)
    super
    @id = id
    @stripped = stripped
    @borderless = borderless
    @layout_fixed = layout_fixed
    @small_text = small_text
    @outline = outline
    @default_sort_column = default_sort_column
    @searching = searching
    @sort = sort
    @paging = paging
    @no_init_sort = no_init_sort
    @auto_layout = auto_layout
    @custom_class =custom_class
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

  def auto_layout_class
    @auto_layout ? 'table-auto-layout' : ''
  end
end

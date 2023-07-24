# frozen_string_literal: true

class TableComponent < ViewComponent::Base

  renders_one :header, TableRowComponent
  renders_many :rows, TableRowComponent

  def initialize(id: '', stripped: true)
    super
    @id = id
    @stripped = stripped
  end

  def stripped_class
    @stripped ? 'table-content-stripped' : ''
  end

  def add_row(*array, &block)
    self.row.create(*array, &block)
  end
end

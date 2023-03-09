class DropOldTables < ActiveRecord::Migration[4.2]
  def self.up
    old_tables = [
      :custom_ontologies,
      :event_items,
      :groups,
      :mapping_import_errors,
      :mappings,
      :margin_notes,
      :notes,
      :notes_indices,
      :projects,
      :rating_types,
      :ratings,
      :reviews,
      :surveys,
      :users,
      :uses,
      :widget_logs,
    ]
    old_tables.each do |table|
      drop_table table rescue next
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

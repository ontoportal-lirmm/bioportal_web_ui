class CreateTimeoutsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :timeouts do |t|
      t.string :path
      t.integer :ontology_id
      t.text :concept_id
      t.text :params
      t.timestamp :created
    end
  end

  def self.down
    drop_table :timeouts
  end
end

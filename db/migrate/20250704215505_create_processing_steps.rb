class CreateProcessingSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :processing_steps do |t|
      t.references :assignment, null: false, foreign_key: true
      t.string :step_key, null: false
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :processing_steps, [ :assignment_id, :step_key ], unique: true
  end
end

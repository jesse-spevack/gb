class CreateProcessingMetric < ActiveRecord::Migration[8.0]
  def change
    create_table :processing_metrics do |t|
      t.references :processable, polymorphic: true, null: false
      t.datetime :completed_at
      t.integer :duration_ms
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end

class AddTimingFieldsToProcessingMetrics < ActiveRecord::Migration[8.0]
  def change
    add_column :processing_metrics, :total_duration_ms, :integer
    add_column :processing_metrics, :llm_duration_ms, :integer
    add_column :processing_metrics, :metrics_data, :json, default: {}
    add_column :processing_metrics, :recorded_at, :datetime

    add_index :processing_metrics, :recorded_at

    # For finding all metrics related to an assignment (including its rubric, student works, etc)
    add_reference :processing_metrics, :assignment, foreign_key: true, index: true

    # For finding all metrics for a user's assignments
    add_reference :processing_metrics, :user, foreign_key: true, index: true
  end
end

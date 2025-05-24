class UpdateLLMUsageRecordFields < ActiveRecord::Migration[8.0]
  def change
    add_column :llm_usage_records, :llm_model, :string, null: false, default: ""
    rename_column :llm_usage_records, :llm, :llm_provider
    remove_column :llm_usage_records, :prompt, :text
    add_index :llm_usage_records, :llm_model
    add_index :llm_usage_records, :created_at
    add_index :llm_usage_records, [ :user_id, :created_at ]
    add_index :llm_usage_records, [ :trackable_type, :trackable_id, :created_at ]
  end
end

class RenameModelNameToLLMModel < ActiveRecord::Migration[8.0]
  def change
    rename_column :llm_usage_records, :model_name, :llm_model
  end
end

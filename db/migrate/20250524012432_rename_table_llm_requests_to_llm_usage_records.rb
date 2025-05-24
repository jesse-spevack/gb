class RenameTableLLMRequestsToLLMUsageRecords < ActiveRecord::Migration[8.0]
  def change
    rename_table :llm_requests, :llm_usage_records
  end
end

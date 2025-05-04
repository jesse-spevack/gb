class CreateLLMRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_requests do |t|
      t.references :trackable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.integer :llm
      t.integer :request_type
      t.integer :token_count
      t.integer :micro_usd
      t.text :prompt

      t.timestamps
    end
  end
end

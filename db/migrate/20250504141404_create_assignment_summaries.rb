class CreateAssignmentSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_summaries do |t|
      t.references :assignment, null: false, foreign_key: true
      t.integer :student_work_count, null: false
      t.text :qualitative_insights, null: false

      t.timestamps
    end
  end
end

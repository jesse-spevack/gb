class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :subject
      t.string :grade_level
      t.text :instructions, null: false
      t.text :rubric_text
      t.string :feedback_tone, default: "encouraging", null: false

      t.timestamps
    end
  end
end

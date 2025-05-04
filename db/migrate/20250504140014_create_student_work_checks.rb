class CreateStudentWorkChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :student_work_checks do |t|
      t.references :student_work, null: false, foreign_key: true
      t.integer :check_type, null: false
      t.integer :score, null: false
      t.text :explanation, null: false

      t.timestamps
    end
  end
end

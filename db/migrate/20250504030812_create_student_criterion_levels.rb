class CreateStudentCriterionLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :student_criterion_levels do |t|
      t.references :student_work, null: false, foreign_key: true
      t.references :criterion, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.text :explanation, null: false

      t.timestamps
    end
  end
end

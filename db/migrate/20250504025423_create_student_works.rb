class CreateStudentWorks < ActiveRecord::Migration[8.0]
  def change
    create_table :student_works do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :selected_document, null: false, foreign_key: true
      t.text :qualitative_feedback

      t.timestamps
    end
  end
end

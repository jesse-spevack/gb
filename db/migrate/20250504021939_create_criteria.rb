class CreateCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :criteria do |t|
      t.references :rubric, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end

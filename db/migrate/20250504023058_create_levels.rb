class CreateLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :levels do |t|
      t.references :criterion, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end

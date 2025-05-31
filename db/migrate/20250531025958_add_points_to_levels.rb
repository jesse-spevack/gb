class AddPointsToLevels < ActiveRecord::Migration[8.0]
  def change
    add_column :levels, :points, :integer, null: false
    add_index :levels, [ :criterion_id, :points ], unique: true
  end
end

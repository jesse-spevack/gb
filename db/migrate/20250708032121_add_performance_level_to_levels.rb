class AddPerformanceLevelToLevels < ActiveRecord::Migration[8.0]
  def change
    add_column :levels, :performance_level, :integer, null: false, default: 0
    add_index :levels, :performance_level

    # Remove the position column as it's being replaced by performance_level
    remove_column :levels, :position, :integer
  end
end

class CreateFeedbackItems < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_items do |t|
      t.references :feedbackable, polymorphic: true, null: false
      t.integer :item_type, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.text :evidence, null: false

      t.timestamps
    end
  end
end

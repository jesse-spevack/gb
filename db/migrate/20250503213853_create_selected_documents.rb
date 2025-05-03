class CreateSelectedDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :selected_documents do |t|
      t.references :assignment, null: false, foreign_key: true
      t.string :google_doc_id, null: false
      t.string :title, null: false
      t.string :url, null: false

      t.timestamps
    end
  end
end

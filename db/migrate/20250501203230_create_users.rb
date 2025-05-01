class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :google_uid, null: false
      t.string :profile_picture_url
      t.boolean :admin, default: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :google_uid, unique: true
  end
end

class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.string :name
      t.string :email
      t.date :birth_date
      t.string :phone_number
      t.references :organization, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true

      t.timestamps
    end
  end
end

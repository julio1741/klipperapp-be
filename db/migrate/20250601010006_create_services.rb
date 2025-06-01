class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :name
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.decimal :price
      t.references :branch, null: false, foreign_key: true
      t.integer :duration
      t.boolean :active

      t.timestamps
    end
  end
end

class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.boolean :is_admin

      t.timestamps
    end
  end
end

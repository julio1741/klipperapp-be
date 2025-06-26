class CreatePayments < ActiveRecord::Migration[6.1]
  def change
    create_table :payments do |t|
      t.float :amount, null: false
      t.references :organization, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :aasm_state, null: false, default: "pending"
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end
  end
end

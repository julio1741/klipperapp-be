class CreateCashReconciliations < ActiveRecord::Migration[7.1]
  def change
    create_table :cash_reconciliations do |t|
      t.integer :reconciliation_type, null: false, default: 0
      t.decimal :cash_amount, precision: 10, scale: 2, default: 0.0
      t.jsonb :bank_balances, default: []
      t.decimal :total_calculated, precision: 10, scale: 2, default: 0.0
      t.decimal :expected_cash, precision: 10, scale: 2
      t.decimal :expected_bank_transfer, precision: 10, scale: 2
      t.decimal :expected_credit_card, precision: 10, scale: 2
      t.decimal :difference_cash, precision: 10, scale: 2
      t.integer :status, default: 0
      t.text :notes
      t.references :user, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cash_reconciliations, :reconciliation_type
    add_index :cash_reconciliations, :status
  end
end

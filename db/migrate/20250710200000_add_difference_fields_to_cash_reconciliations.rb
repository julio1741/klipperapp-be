class AddDifferenceFieldsToCashReconciliations < ActiveRecord::Migration[7.1]
  def change
    add_column :cash_reconciliations, :difference_pos, :decimal, precision: 10, scale: 2
    add_column :cash_reconciliations, :difference_transfer, :decimal, precision: 10, scale: 2
  end
end

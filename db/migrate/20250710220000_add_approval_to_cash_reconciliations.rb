class AddApprovalToCashReconciliations < ActiveRecord::Migration[7.1]
  def change
    add_column :cash_reconciliations, :approved_at, :datetime
    add_reference :cash_reconciliations, :approved_by_user, foreign_key: { to_table: :users }
  end
end

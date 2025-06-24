class AddBranchAndQuantityToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_reference :expenses, :branch, null: false, foreign_key: true
    add_column :expenses, :quantity, :integer
  end
end

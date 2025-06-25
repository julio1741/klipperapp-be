class AddTypeToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_column :expenses, :type, :string
  end
end

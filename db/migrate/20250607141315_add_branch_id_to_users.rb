class AddBranchIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :branch_id, :integer
    add_index :users, :branch_id
  end
end

class DropBranchUsers < ActiveRecord::Migration[7.0]
  def change
    drop_table :branch_users
  end
end

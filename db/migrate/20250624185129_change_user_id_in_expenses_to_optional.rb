class ChangeUserIdInExpensesToOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :expenses, :user_id, true
  end
end

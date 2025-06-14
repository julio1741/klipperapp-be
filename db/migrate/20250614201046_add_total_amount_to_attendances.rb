class AddTotalAmountToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :total_amount, :integer
  end
end

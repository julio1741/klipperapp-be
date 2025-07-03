class AddTipAmountToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :tip_amount, :integer
  end
end

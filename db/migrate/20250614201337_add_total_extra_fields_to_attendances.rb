class AddTotalExtraFieldsToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :trx_number, :string
    add_column :attendances, :payment_method, :string
  end
end

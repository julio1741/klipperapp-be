class AddFieldsToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :discount, :integer
    add_column :attendances, :extra_discount, :integer
    add_column :attendances, :user_amount, :integer
    add_column :attendances, :organization_amount, :integer
    add_column :attendances, :start_attendance_at, :timestamp
    add_column :attendances, :end_attendance_at, :timestamp
  end
end

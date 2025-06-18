class AddParentAttendanceIdToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :parent_attendance_id, :integer
    add_index :attendances, :parent_attendance_id
  end
end

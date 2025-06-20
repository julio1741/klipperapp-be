class AddLastAttendanceAtToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :last_attendance_at, :timestamp
  end
end

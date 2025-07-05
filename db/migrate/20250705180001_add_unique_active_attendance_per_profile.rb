class AddUniqueActiveAttendancePerProfile < ActiveRecord::Migration[6.1]
  def change
    # Solo para PostgreSQL: índice único parcial para evitar duplicados en estados activos
    add_index :attendances, [:profile_id, :status], unique: true, where: "status IN ('pending', 'processing', 'postponed')", name: 'unique_active_attendance_per_profile'
  end
end

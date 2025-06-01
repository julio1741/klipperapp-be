class AddAttendedByToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :attended_by, :integer
    add_foreign_key :attendances, :users, column: :attended_by
  end
end

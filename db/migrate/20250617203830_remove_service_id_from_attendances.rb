class RemoveServiceIdFromAttendances < ActiveRecord::Migration[7.1]
  def change
    remove_column :attendances, :service_id, :integer
  end
end

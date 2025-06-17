class CreateAttendancesServicesJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :attendances, :services do |t|

      t.timestamps
    end
  end
end

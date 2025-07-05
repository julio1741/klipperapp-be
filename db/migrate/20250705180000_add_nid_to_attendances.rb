class AddNidToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :nid, :string
    add_index :attendances, [:date, :nid], unique: true
  end
end

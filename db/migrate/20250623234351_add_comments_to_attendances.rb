class AddCommentsToAttendances < ActiveRecord::Migration[7.1]
  def change
    add_column :attendances, :comments, :text
  end
end

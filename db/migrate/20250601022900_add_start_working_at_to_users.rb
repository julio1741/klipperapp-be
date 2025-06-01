class AddStartWorkingAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :start_working_at, :datetime
  end
end

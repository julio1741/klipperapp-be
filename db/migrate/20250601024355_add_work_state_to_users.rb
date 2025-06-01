class AddWorkStateToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :work_state, :string
  end
end

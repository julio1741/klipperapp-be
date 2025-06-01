class CreateBranchUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :branch_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true

      t.timestamps
    end
  end
end

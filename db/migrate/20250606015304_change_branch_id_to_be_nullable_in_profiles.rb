class ChangeBranchIdToBeNullableInProfiles < ActiveRecord::Migration[7.1]
  def change
    change_column_null :profiles, :branch_id, true
  end
end

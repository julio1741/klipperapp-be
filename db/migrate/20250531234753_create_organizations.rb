class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :slug
      t.json :metadata
      t.string :bio

      t.timestamps
    end
  end
end

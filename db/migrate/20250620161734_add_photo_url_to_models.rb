class AddPhotoUrlToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :photo_url, :string
    add_column :branches, :photo_url, :string
    add_column :organizations, :photo_url, :string
    add_column :users, :photo_url, :string
    add_column :services, :photo_url, :string
  end
end

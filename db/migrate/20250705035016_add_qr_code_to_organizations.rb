class AddQrCodeToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :qr_code, :string
  end
end

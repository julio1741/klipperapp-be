class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :role_id,
  :organization_id, :branch_id, :active, :photo_url, :work_state
end

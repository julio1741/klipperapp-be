class User < ApplicationRecord
  has_secure_password

  belongs_to :role
  belongs_to :organization

  has_many :branch_users
  has_many :branches, through: :branch_users

  validates :email, presence: true, uniqueness: true
  validates :name, :phone_number, presence: true
end

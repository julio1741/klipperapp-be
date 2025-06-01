class Role < ApplicationRecord
  belongs_to :organization
  belongs_to :branch

  has_many :users, dependent: :nullify

  validates :name, presence: true
end

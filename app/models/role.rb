class Role < ApplicationRecord
  include Filterable
  belongs_to :organization
  belongs_to :branch

  has_many :users, dependent: :nullify

  validates :name, presence: true
end

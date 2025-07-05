class Role < ApplicationRecord
  include Filterable
  belongs_to :organization, optional: true
  belongs_to :branch, optional: true

  has_many :users, dependent: :nullify

  validates :name, presence: true
end

class Expense < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  belongs_to :branch

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end

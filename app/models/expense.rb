class Expense < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
end

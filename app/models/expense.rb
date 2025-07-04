class Expense < ApplicationRecord
  include Filterable
  self.inheritance_column = :_type_disabled # Desactiva STI para la columna `type`

  belongs_to :organization
  belongs_to :user, optional: true
  belongs_to :branch

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end

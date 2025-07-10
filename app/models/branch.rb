class Branch < ApplicationRecord
  include Filterable
  belongs_to :organization
  has_many :cash_reconciliations
end

class Branch < ApplicationRecord
  include Filterable
  belongs_to :organization
end

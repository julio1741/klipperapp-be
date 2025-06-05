class Service < ApplicationRecord
  include Filterable
  belongs_to :organization
  belongs_to :branch
end

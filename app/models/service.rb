class Service < ApplicationRecord
  include Filterable
  belongs_to :organization
  belongs_to :branch
  has_and_belongs_to_many :attendances
end

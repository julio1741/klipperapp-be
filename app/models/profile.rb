class Profile < ApplicationRecord
  include Filterable
  belongs_to :organization
  belongs_to :branch, optional: true
end

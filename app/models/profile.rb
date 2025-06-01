class Profile < ApplicationRecord
  belongs_to :organization
  belongs_to :branch
end

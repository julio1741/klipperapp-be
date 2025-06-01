class BranchUser < ApplicationRecord
  belongs_to :user
  belongs_to :branch
end

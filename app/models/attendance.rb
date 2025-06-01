class Attendance < ApplicationRecord
  include AASM

  belongs_to :profile
  belongs_to :service
  belongs_to :organization
  belongs_to :branch

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :completed
    state :finished
    state :canceled

    event :start do
      transitions from: :pending, to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :finish do
      transitions from: [:completed, :processing], to: :finished
    end

    event :cancel do
      transitions from: [:pending, :processing, :completed], to: :canceled
    end
  end
end

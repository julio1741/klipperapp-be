class Attendance < ApplicationRecord
  include AASM
  include Filterable

  belongs_to :profile
  belongs_to :service
  belongs_to :organization
  belongs_to :branch
  belongs_to :attended_by_user, class_name: "User", foreign_key: :attended_by, optional: true

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

  # Método para cancelar attendances pendientes de días anteriores
  def self.cancel_old_pending_attendances
    where(status: :pending)
      .where("created_at < ?", Time.now.beginning_of_day)
      .find_each do |attendance|
        attendance.cancel!
      end
  end
end

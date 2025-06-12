class Attendance < ApplicationRecord
  include AASM
  include Filterable

  belongs_to :profile
  belongs_to :service
  belongs_to :organization
  belongs_to :branch
  belongs_to :attended_by_user, class_name: "User", foreign_key: :attended_by, optional: true

  after_create :set_attended_by, if: -> { attended_by.nil? }

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

  def set_attended_by
    assign_service = AssignBarberService.new(
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      role_id: 2) # Buscar otra forma de obtener el role id
    user = assign_service.call
    self.attended_by = user.id if user
    save
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

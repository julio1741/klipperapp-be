class Attendance < ApplicationRecord
  include AASM
  include Filterable

  belongs_to :profile
  belongs_to :service
  belongs_to :organization
  belongs_to :branch
  belongs_to :attended_by_user, class_name: "User", foreign_key: :attended_by, optional: true

  after_create :set_attended_by, if: -> { attended_by.nil? }
  # update user list after destroy

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :completed
    state :finished
    state :canceled

    event :start do
      transitions from: :pending, to: :processing, after: [:set_start_attendance]
    end

    event :complete do
      transitions from: :processing, to: :completed, after: [:set_end_attendance]
    end

    event :finish do
      transitions from: [:completed, :processing], to: :finished
    end

    event :cancel do
      transitions from: [:pending, :processing, :completed], to: :canceled
    end
  end

  def set_start_attendance
    self.start_attendance_at = Time.now.in_time_zone('America/Santiago')
    save
  end

  def set_end_attendance
    self.end_attendance_at = Time.now.in_time_zone('America/Santiago')
    save
  end

  def set_attended_by
    assign_service = UserQueueService.new(
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      role_name: "agent") # Buscar otra forma de obtener el role id
    user = assign_service.next_available
    self.attended_by = user.id if user
    save
  end

  # Metodo para obtener si un profile ya esta en un attendance en proceso o pendiente del día de hoy
  def self.profile_in_attendance_today?(profile_id)
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(profile_id: profile_id)
      .where(status: [:pending, :processing])
      .where("created_at >= ?", today)
      .exists?
  end

  # Método para obtener attendances pendiente del día de hoy de un usuario
  def self.pending_attendances_today_by_user(user_id)
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(attended_by: user_id)
      .where(status: [:pending, :processing])
      .where("created_at >= ?", today)
  end

  # Método para obtener attendances pendientes del día de hoy
  def self.pending_attendances_today
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(status: [:pending, :processing])
      .where("created_at >= ?", today)
      .order(:created_at)
  end

  # Método para cancelar attendances pendientes de días anteriores
  def self.cancel_old_pending_attendances
    where(status: [:pending, :processing])
      .where("created_at <= ?", Time.now.in_time_zone('America/Santiago').end_of_day)
      .find_each do |attendance|
        attendance.cancel!
      end
  end

end

class Attendance < ApplicationRecord
  include AASM
  include Filterable
  include PusherBroadcastable

  belongs_to :profile
  belongs_to :organization
  belongs_to :branch
  belongs_to :attended_by_user, class_name: "User", foreign_key: :attended_by, optional: true

  has_and_belongs_to_many :services

  # Relación jerárquica para agrupar attendances
  belongs_to :parent_attendance, class_name: "Attendance", optional: true
  has_many :child_attendances, class_name: "Attendance", foreign_key: :parent_attendance_id, dependent: :nullify


  after_create :set_attended_by
  # update user list after destroy

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :completed
    state :finished
    state :postponed
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

    event :postpone do
      transitions from: [:pending, :processing], to: :postponed
    end

    event :resume do
      transitions from: :postponed, to: :processing
    end

    event :cancel do
      transitions from: [:pending, :processing, :completed, :postponed], to: :canceled
    end
  end

  def send_message_to_frontend
    data = {
      id: self.id,
      status: self.status,
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      attended_by: self.attended_by,
      profile: self.profile.as_json
    }
    broadcast_pusher('attendance_channel', 'attendance', data)
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
    if attended_by.nil?
      user = assign_service.next_available
      self.attended_by = user.id if user
    end
    self.attended_by_user.start_attendance!
    #assign_service.rotate(self.attended_by_user) (ya el start_attendnace lo hace)
    save
  end

  def set_profile_last_attended_date profile_id
    profile = Profile.find_by(id: profile_id)
    if profile
      profile.touch(:last_attendance_at)
    end
  end

  # Metodo para obtener si un profile ya esta en un attendance en proceso o pendiente del día de hoy
  def self.profile_in_attendance_today?(profile_id)
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(profile_id: profile_id)
      .where(status: [:pending, :processing, :postponed])
      .where("created_at >= ?", today)
      .exists?
  end

  # Método para obtener attendances pendiente del día de hoy de un usuario
  def self.pending_attendances_today_by_user(user_id)
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(attended_by: user_id)
      .where(status: [:pending, :processing, :postponed])
      .where("created_at >= ?", today)
  end

  # Método para obtener attendances pendientes del día de hoy
  def self.pending_attendances_today
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    where(status: [:pending, :processing, :postponed])
      .where("created_at >= ?", today)
      .order(:created_at)
  end

  # Método para cancelar attendances pendientes de días anteriores
  def self.cancel_old_pending_attendances
    where(status: [:pending, :processing, :postponed])
      .where("created_at <= ?", Time.now.in_time_zone('America/Santiago').end_of_day)
      .find_each do |attendance|
        attendance.cancel!
      end
    broadcast_pusher('attendance_channel', 'attendance', {})
  end

  before_create :generate_nid
  validate :unique_profile_per_day_pending_processing, on: :create

  private

  def generate_nid
    today = self.date || Date.current
    last_nid = Attendance.where(date: today).order(:nid).pluck(:nid).last
    if last_nid.present?
      last_number = last_nid[1..-1].to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    self.nid = "A#{next_number.to_s.rjust(3, '0')}"
  end

  def unique_profile_per_day_pending_processing
    today = self.date || Date.current
    exists = Attendance.where(date: today, profile_id: profile_id, status: [:pending, :processing]).exists?
    if exists
      errors.add(:base, "Ya existe una asistencia para este perfil en estado pendiente o en proceso hoy.")
    end
  end
end

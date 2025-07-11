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

  before_create :generate_nid
  after_create :set_attended_by
  validate :unique_profile_per_day_pending_processing, on: :create

  # update user list after destroy

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :completed
    state :finished
    state :postponed
    state :canceled

    event :start do
      transitions from: :pending, to: :processing, after: [:set_start_attendance], guard: :user_has_no_other_processing_attendance?
    end

    event :complete do
      transitions from: :processing, to: :completed, after: [:set_end_attendance]
    end

    event :finish do
      transitions from: [:completed, :processing], to: :finished
    end

    event :postpone do
      transitions from: [:pending, :processing], to: :postponed, after: [:send_message_to_frontend]
    end

    event :resume do
      transitions from: :postponed, to: :processing, guard: :user_has_no_other_processing_attendance?, after: [:send_message_to_frontend]
    end

    event :cancel do
      transitions from: [:pending, :processing, :completed, :postponed], to: :canceled
    end

    event :reopen do
      transitions from: :completed, to: :processing, guard: :user_has_no_other_processing_attendance?, after: :reactivate_user_for_service
    end
  end

  def send_message_to_frontend
    # Forzamos a recargar el objeto y refrescar el status desde la base de datos
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
    data = {
      id: self.id,
      status: self.status,
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      attended_by: self.attended_by,
      profile: self.profile.as_json
    }
    broadcast_pusher('attendance_channel', 'attendance', data)
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

  # Determina si una attendance es clickeable según la lógica de negocio
  def clickeable?
    # Si es processing, siempre es clickeable
    return true if processing?

    # Si es postponed, es clickeable salvo que el usuario tenga una en processing
    if postponed?
      return !Attendance.where(attended_by: attended_by, status: :processing)
        .where("created_at >= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day)
        .exists?
    end

    # Si es pending, solo el primero (más antiguo) es clickeable y solo si no hay processing
    if pending?
      return false if Attendance.where(attended_by: attended_by, status: :processing)
        .where("created_at >= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day)
        .exists?
      first_pending = Attendance.where(attended_by: attended_by, status: :pending)
        .where("created_at >= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day)
        .order(:created_at).first
      return self.id == first_pending&.id
    end

    # Otros estados no son clickeables
    false
  end

  private

  def generate_nid
    today = Time.now.in_time_zone('America/Santiago').to_date
    last_nid = Attendance.where("DATE(created_at) = ?", today).where.not(nid: nil).order(:nid).pluck(:nid).last
    if last_nid.present?
      last_number = last_nid[1..-1].to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    self.nid = "A#{next_number.to_s.rjust(3, '0')}"
  end

  def unique_profile_per_day_pending_processing
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    exists = Attendance.where(profile_id: profile_id)
      .where(status: [:pending, :processing, :postponed])
      .where("created_at >= ?", today)
      .where.not(id: id) # Por si acaso en update
      .exists?
    if exists
      errors.add(:base, "Ya existe una asistencia para este perfil en estado pendiente, en proceso o pospuesta hoy.")
    end
  end

  def user_has_no_other_processing_attendance?
    return true unless attended_by_user # Si no hay usuario asignado, permitir
    Attendance.where(attended_by: attended_by_user.id, status: :processing)
      .where.not(id: id)
      .where("created_at >= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day)
      .none?
  end

  private

  def reactivate_user_for_service
    return unless attended_by_user

    # Si el usuario estaba 'available', debe pasar a 'working' y salir de la cola.
    # El evento start_attendance! en User ya maneja esta lógica.
    if attended_by_user.may_start_attendance?
      attended_by_user.start_attendance!
    end

    self.reload # Asegura que el status esté actualizado tras la transición
  end
end

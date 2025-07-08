class User < ApplicationRecord
  include AASM
  include Filterable
  include PusherBroadcastable
  has_secure_password

  belongs_to :role
  belongs_to :organization
  belongs_to :branch, optional: true # Ahora un usuario pertenece a un branch
  has_many :attendances, foreign_key: :attended_by, dependent: :destroy
  has_many :payments

  validates :email, presence: true, uniqueness: true
  validates :name, :phone_number, presence: true
  #validates :start_working_at, presence: true, if: -> { active? }

  # order by start_working_at ascending
  scope :users_working_today, -> (organization_id, branch_id, role_id) {
      where.not(start_working_at: nil)
      .where("start_working_at >= ? AND organization_id = ? AND branch_id = ? AND role_id = ?", Time.now.in_time_zone('America/Santiago').beginning_of_day, organization_id, branch_id, role_id).order(:start_working_at)
  }

  after_update :set_today_users_list, if: -> { saved_change_to_start_working_at? }

  before_create :set_email_verification

  aasm column: 'work_state' do
    state :stand_by, initial: true
    state :working
    state :available
    state :not_available

    event :start_shift do
      transitions from: [:stand_by, :available], to: :available, after: [:set_start_working_at]
    end

    event :not_available do
      transitions from: [:available], to: :not_available, guard: :no_active_attendances_today?, after: [:remove_user_from_queue, :send_message_to_frontend]
    end

    event :available do
      transitions from: [:stand_by, :not_available], to: :available, after: [:add_user_to_queue, :send_message_to_frontend]
    end

    event :start_attendance do
      transitions from: [:available, :working], to: :working, after: :remove_user_from_queue
    end

    event :end_attendance do
      transitions from: :working, to: :available, guard: :no_active_attendances_today?, after: :add_user_to_queue
    end

    event :set_stand_by do
      transitions from: [:stand_by, :working, :available, :not_available], to: :stand_by
    end

    event :end_shift do
      transitions from: [:available, :working], to: :stand_by, after: :set_end_working_at_nil
    end
  end

  def add_user_to_queue
    assign_service = UserQueueService.new(
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      role_name: "agent")
    assign_service.add_user_to_queue(self)
  end

  def add_user_to_order_queue
    assign_service = UserQueueService.new(
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      role_name: "agent")
    assign_service.add_user_to_order_queue(self)
  end

  def remove_user_from_queue
    assign_service = UserQueueService.new(
      organization_id: self.organization_id,
      branch_id: self.branch_id,
      role_name: "agent")
    assign_service.remove(self)
  end

  def send_message_to_frontend
    data = {}
    broadcast_pusher('attendance_channel', 'attendance', data)
  end

  def working_today?
    start_working_at&.to_date == Date.today
  end

  # set users on stand by
  def self.set_users_stand_by
    where(work_state: [:stand_by, :working, :available, :not_available]).each do |user|
      user.update(start_working_at: nil)
      user.set_stand_by!
    end
  end

  def set_today_users_list
    today = Time.current.in_time_zone('America/Santiago').to_date
    redis_key = "user_rotation_list:org:#{organization_id}:branch:#{branch_id}:#{today}"
    user_ids = Rails.cache.read(redis_key)
    if user_ids.blank?
      # Generamos la lista desde cero (orden justo inicial)
      self.class.build_initial_queue(organization_id, branch_id)
    end
  end

  def self.build_initial_queue(organization_id, branch_id)
    today = Time.current.in_time_zone('America/Santiago').to_date
    role = Role.find_by(name: 'agent')
    redis_key = "user_rotation_list:org:#{organization_id}:branch:#{branch_id}:#{today}"
    user_ids = User
      .where(organization_id: organization_id)
      .where(branch_id: branch_id)
      .where(role_id: role.id)
      .where('start_working_at >= ?', today.beginning_of_day)
      .group('users.id')
      .order('start_working_at ASC')
      .pluck('users.id')
    Rails.cache.write(redis_key, user_ids, expires_in: 12.hours)
  end

  private

  def set_start_working_at
    self.start_working_at = Time.now.in_time_zone('America/Santiago')
    add_user_to_queue
    add_user_to_order_queue
    broadcast_pusher('attendance_channel', 'attendance', {})
    save
  end

    def set_end_working_at_nil
    self.start_working_at = nil
    save
  end

  def set_email_verification
    self.email_verified = false
    self.email_verification_code = SecureRandom.hex(3).upcase # 6-char code
  end

  def no_active_attendances_today?
    today = Time.now.in_time_zone('America/Santiago').beginning_of_day
    !attendances.where(status: [:pending, :processing, :postponed]).where("created_at >= ?", today).exists?
  end
end

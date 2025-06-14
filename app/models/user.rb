class User < ApplicationRecord
  include AASM
  include Filterable
  has_secure_password

  belongs_to :role
  belongs_to :organization
  belongs_to :branch, optional: true # Ahora un usuario pertenece a un branch
  has_many :attendances, foreign_key: :attended_by, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, :phone_number, presence: true
  #validates :start_working_at, presence: true, if: -> { active? }

  # order by start_working_at ascending
  scope :users_working_today, -> (organization_id, branch_id, role_id) {
      where.not(start_working_at: nil)
      .where("start_working_at >= ? AND organization_id = ? AND branch_id = ? AND role_id = ?", Time.now.in_time_zone('America/Santiago').beginning_of_day, organization_id, branch_id, role_id).order(:start_working_at)
  }

  after_update :set_today_users_list, if: -> { saved_change_to_start_working_at? }

  aasm column: 'work_state' do
    state :stand_by, initial: true
    state :working
    state :available

    event :start_shift do
      transitions from: [:stand_by, :available], to: :available, after: :set_start_working_at
    end

    event :not_available do
      transitions from: [:available], to: :not_available
    end

    event :available do
      transitions from: [:stand_by, :not_available], to: :available
    end

    event :start_attendance do
      transitions from: :available, to: :working, after: [:pop_user_from_queue]
    end

    event :end_attendance do
      transitions from: :working, to: :available, after: [:push_user_if_needed]
    end

    event :set_stand_by do
      transitions from: [:working, :available, :not_available], to: :stand_by
    end

    event :end_shift do
      transitions from: [:available, :working], to: :stand_by, after: :set_end_working_at_nil
    end
  end

  def pop_user_from_queue
    User.pop_user_from_queue(self.id)
  end

  def push_user_if_needed
    # verify if user does not have any pending attendances
    if attendances.where(status: [:pending, :processing]).where("created_at >= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day).empty?
      self.class.push_user_to_queue(self.id)
    end
  end

  def self.pop_user_from_queue user_id
    user = User.find_by(id: user_id)
    return unless user
    organization_id = user.organization_id
    branch_id = user.branch_id
    today = Time.current.in_time_zone('America/Santiago').to_date
    redis_key = "user_rotation_list:org:#{organization_id}:branch:#{branch_id}:#{today}"
    user_ids = Rails.cache.read(redis_key)
    if user_ids.present?
      # Remove working user from the queue
      user_ids.delete(user_id)
      Rails.cache.write(redis_key, user_ids, expires_in: 12.hours)
      # If the queue is empty, reset it
      if user_ids.empty?
        Rails.cache.delete(redis_key)
        user.set_today_users_list
      end
    end
  end

  def self.push_user_to_queue user_id
    user = User.find_by(id: user_id)
    return unless user
    organization_id = user.organization_id
    branch_id = user.branch_id
    today = Time.current.in_time_zone('America/Santiago').to_date
    redis_key = "user_rotation_list:org:#{organization_id}:branch:#{branch_id}:#{today}"
    user_ids = Rails.cache.read(redis_key) || []
    unless user_ids.include?(user_id)
      # Add user back to the queue
      user_ids << user_id
      Rails.cache.write(redis_key, user_ids, expires_in: 12.hours)
    end
  end

  def working_today?
    start_working_at&.to_date == Date.today
  end

  # set users on stand by
  def self.set_users_stand_by
    where(work_state: [:working, :available, :not_available]).each do |user|
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
    save
  end

    def set_end_working_at_nil
    self.start_working_at = nil
    save
  end
end

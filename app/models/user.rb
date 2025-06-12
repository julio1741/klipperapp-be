class User < ApplicationRecord
  include AASM
  include Filterable
  has_secure_password

  belongs_to :role
  belongs_to :organization
  belongs_to :branch, optional: true # Ahora un usuario pertenece a un branch

  validates :email, presence: true, uniqueness: true
  validates :name, :phone_number, presence: true
  #validates :start_working_at, presence: true, if: -> { active? }

  # order by start_working_at ascending
  scope :users_working_today, -> (organization_id, branch_id, role_id) {
      where.not(start_working_at: nil)
      .where("start_working_at >= ? AND organization_id = ? AND branch_id = ? AND role_id = ?", Time.now.in_time_zone('America/Santiago').beginning_of_day, organization_id, branch_id, role_id).order(:start_working_at)
  }

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
      transitions from: :available, to: :working
    end

    event :end_attendance do
      transitions from: :working, to: :available
    end

    event :set_stand_by do
      transitions from: [:working, :available, :not_available], to: :stand_by
    end

    event :end_shift do
      transitions from: [:available, :working], to: :stand_by, after: :set_end_working_at_nil
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

class User < ApplicationRecord
  include AASM
  include Filterable
  has_secure_password

  belongs_to :role
  belongs_to :organization

  has_many :branch_users
  has_many :branches, through: :branch_users
  has_many :attended_appointments, class_name: "Attendance", foreign_key: :attended_by

  validates :email, presence: true, uniqueness: true
  validates :name, :phone_number, presence: true
  #validates :start_working_at, presence: true, if: -> { active? }

  # order by start_working_at ascending
  scope :barbers_working_today, ->  {
      where.not(start_working_at: nil)
      .where("start_working_at >= ?", Time.now.in_time_zone('Santiago').beginning_of_day).order(:start_working_at)
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

    event :end_shift do
      transitions from: [:available, :working], to: :stand_by, after: :set_end_working_at_nil
    end
  end

  def working_today?
    start_working_at&.to_date == Date.today
  end

  private

  def set_start_working_at
    self.start_working_at = Time.now.in_time_zone('Santiago')
    save
  end

    def set_end_working_at_nil
    self.start_working_at = nil
    save
  end
end

require 'sidekiq-scheduler'

class CancelOldAttendancesJob
  include Sidekiq::Job

  def perform
    Attendance.cancel_old_pending_attendances
  end
end

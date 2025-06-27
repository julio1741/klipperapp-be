class AttendancesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "attendances"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

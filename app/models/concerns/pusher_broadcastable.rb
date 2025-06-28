module PusherBroadcastable
  extend ActiveSupport::Concern

  class_methods do
    def broadcast_pusher(channel, event, payload)
      Pusher.trigger(channel, event, payload)
    end
  end

  def broadcast_pusher(channel, event, payload)
    Pusher.trigger(channel, event, payload)
  end
end
